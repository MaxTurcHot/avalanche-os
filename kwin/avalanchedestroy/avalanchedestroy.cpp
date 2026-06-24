/*
    Avalanche OS — AvalancheDestroy KWin effect
    Derived from KWin FallApart effect (GPL-2.0-or-later)
    SPDX-FileCopyrightText: 2007 Lubos Lunak <l.lunak@kde.org>
    SPDX-FileCopyrightText: 2026 Maxime Turcotte
    SPDX-License-Identifier: GPL-2.0-or-later

    Physics: tiles fall downward with avalanche cascade dynamics.
    Upper tiles have more kinetic energy (caught by the slide from above),
    the front widens as it descends, and all pieces are swept downward.
*/

#include "avalanchedestroy.h"
#include "avalanchedestroyconfig.h"
#include "effect/effecthandler.h"

#include <QEasingCurve>
#include <cmath>

using namespace std::chrono_literals;

Q_LOGGING_CATEGORY(KWIN_AVALANCHEDESTROY, "kwin_effect_avalanchedestroy", QtWarningMsg)

namespace KWin
{

bool AvalancheDestroyEffect::supported()
{
    return OffscreenEffect::supported() && effects->animationsSupported();
}

AvalancheDestroyEffect::AvalancheDestroyEffect()
{
    AvalancheDestroyConfig::instance(effects->config());
    reconfigure(ReconfigureAll);
    connect(effects, &EffectsHandler::windowClosed, this, &AvalancheDestroyEffect::slotWindowClosed);
    connect(effects, &EffectsHandler::windowDataChanged, this, &AvalancheDestroyEffect::slotWindowDataChanged);
}

void AvalancheDestroyEffect::reconfigure(ReconfigureFlags)
{
    AvalancheDestroyConfig::self()->read();
    blockSize = AvalancheDestroyConfig::blockSize();
}

void AvalancheDestroyEffect::prePaintScreen(ScreenPrePaintData &data)
{
    if (!windows.isEmpty()) {
        data.mask |= PAINT_SCREEN_WITH_TRANSFORMED_WINDOWS;
    }
    effects->prePaintScreen(data);
}

void AvalancheDestroyEffect::prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data)
{
    auto animationIt = windows.find(w);
    if (animationIt != windows.end() && isRealWindow(w)) {
        const int time = animationIt->clock.tick(view).count();
        animationIt->progress += double(time) / animationTime(600ms).count();
        data.setTransformed();
    }
    effects->prePaintWindow(view, w, data);
}

void AvalancheDestroyEffect::apply(EffectWindow *w, int mask, WindowPaintData &data, WindowQuadList &quads)
{
    auto animationIt = windows.constFind(w);
    if (animationIt != windows.constEnd() && isRealWindow(w)) {
        QEasingCurve easing(QEasingCurve::InCubic);
        const qreal t = easing.valueForProgress(animationIt->progress);

        quads = quads.makeGrid(blockSize);
        int cnt = 0;

        for (WindowQuad &quad : quads) {
            QPointF p1(quad[0].x(), quad[0].y());

            // Normalized position within the window: 0.0 = top/left, 1.0 = bottom/right
            const double normX = (p1.x() - w->width() / 2.0) / w->width();  // -0.5..+0.5
            const double normY = p1.y() / w->height();                        //  0.0..1.0

            // --- Avalanche X physics ---
            // Tiles spread outward from center as the avalanche front widens.
            // Tiles near the bottom travel further laterally (the front has fully opened).
            double xdiff = normX * (80.0 + normY * 60.0);

            // --- Avalanche Y physics ---
            // All tiles fall downward (gravity).
            // Tiles near the TOP have more kinetic energy — they were caught by the
            // slide coming from above and have been accelerating longer.
            double ydiff = 60.0 + (1.0 - normY) * 80.0;

            // Small random jitter for powder-snow turbulence.
            srandom(cnt);
            xdiff += (rand() % 21 - 10);
            ydiff += (rand() % 16 - 4);   // biased slightly positive so pieces fall, not rise

            const double modif = t * 64.0;
            for (int j = 0; j < 4; ++j) {
                quad[j].move(quad[j].x() + xdiff * modif,
                             quad[j].y() + ydiff * modif);
            }

            // Spin — each tile tumbles as it falls.
            QPointF center(
                (quad[0].x() + quad[1].x() + quad[2].x() + quad[3].x()) / 4,
                (quad[0].y() + quad[1].y() + quad[2].y() + quad[3].y()) / 4);
            const double adiff = (rand() % 720 - 360) / 360.0 * 2 * M_PI;
            for (int j = 0; j < 4; ++j) {
                double x = quad[j].x() - center.x();
                double y = quad[j].y() - center.y();
                double angle = atan2(y, x) + animationIt->progress * adiff;
                double dist = sqrt(x * x + y * y);
                quad[j].move(center.x() + dist * cos(angle),
                             center.y() + dist * sin(angle));
            }

            ++cnt;
        }

        data.multiplyOpacity(interpolate(1.0, 0.0, t));
    }
}

void AvalancheDestroyEffect::postPaintScreen()
{
    for (auto it = windows.begin(); it != windows.end();) {
        if (it->progress < 1) {
            ++it;
        } else {
            unredirect(it.key());
            it = windows.erase(it);
        }
    }
    effects->addRepaintFull();
    effects->postPaintScreen();
}

bool AvalancheDestroyEffect::isRealWindow(EffectWindow *w)
{
    if (w->isPopupWindow()) return false;
    if (w->isOutline())     return false;
    if (w->isLockScreen())  return false;
    if (w->isX11Client() && !w->isManaged()) return false;
    if (!w->isNormalWindow()) return false;
    return true;
}

void AvalancheDestroyEffect::slotWindowClosed(EffectWindow *c)
{
    if (effects->activeFullScreenEffect()) return;
    if (!isRealWindow(c)) return;
    if (!c->isVisible()) return;

    const void *e = c->data(WindowClosedGrabRole).value<void *>();
    if (e && e != this) return;

    c->setData(WindowClosedGrabRole, QVariant::fromValue(static_cast<void *>(this)));
    AvalancheDestroyAnimation &animation = windows[c];
    animation.progress = 0;
    animation.deletedRef = EffectWindowDeletedRef(c);
    redirect(c);
}

void AvalancheDestroyEffect::slotWindowDataChanged(EffectWindow *w, int role)
{
    if (role != WindowClosedGrabRole) return;
    if (w->data(role).value<void *>() == this) return;

    auto it = windows.find(w);
    if (it != windows.end()) {
        unredirect(it.key());
        windows.erase(it);
    }
}

bool AvalancheDestroyEffect::isActive() const
{
    return !windows.isEmpty();
}

} // namespace

#include "moc_avalanchedestroy.cpp"
