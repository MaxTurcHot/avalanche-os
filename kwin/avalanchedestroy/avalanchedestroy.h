/*
    Avalanche OS — AvalancheDestroy KWin effect
    Derived from KWin FallApart effect (GPL-2.0-or-later)
    SPDX-FileCopyrightText: 2007 Lubos Lunak <l.lunak@kde.org>
    SPDX-FileCopyrightText: 2026 Maxime Turcotte
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#pragma once

#include "effect/effectwindow.h"
#include "effect/offscreeneffect.h"
#include "effect/timeline.h"

namespace KWin
{

struct AvalancheDestroyAnimation
{
    EffectWindowDeletedRef deletedRef;
    AnimationClock clock;
    qreal progress = 0;
};

class AvalancheDestroyEffect : public OffscreenEffect
{
    Q_OBJECT
    Q_PROPERTY(int blockSize READ configuredBlockSize)

public:
    AvalancheDestroyEffect();
    void reconfigure(ReconfigureFlags) override;
    void prePaintScreen(ScreenPrePaintData &data) override;
    void prePaintWindow(RenderView *view, EffectWindow *w, WindowPrePaintData &data) override;
    void postPaintScreen() override;
    bool isActive() const override;

    int requestedEffectChainPosition() const override { return 70; }
    int configuredBlockSize() const { return blockSize; }

    static bool supported();

protected:
    void apply(EffectWindow *w, int mask, WindowPaintData &data, WindowQuadList &quads) override;

public Q_SLOTS:
    void slotWindowClosed(KWin::EffectWindow *c);
    void slotWindowDataChanged(KWin::EffectWindow *w, int role);

private:
    QHash<EffectWindow *, AvalancheDestroyAnimation> windows;
    bool isRealWindow(EffectWindow *w);
    int blockSize;
};

} // namespace
