#pragma once
#include <SFML/Graphics.h>
#include <box2d/box2d.h>
#include "bw.h"

BW_EXPORT sfSprite* bwLoadSprite(const char* path);

BW_EXPORT void bwProcessEvents(b2WorldId worldId);