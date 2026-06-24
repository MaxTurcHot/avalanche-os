/*
    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-FileCopyrightText: 2026 Maxime Turcotte
    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "avalanchedestroy.h"

namespace KWin
{

KWIN_EFFECT_FACTORY_SUPPORTED(AvalancheDestroyEffect,
                              "metadata.json",
                              return AvalancheDestroyEffect::supported();)

} // namespace KWin

#include "main.moc"
