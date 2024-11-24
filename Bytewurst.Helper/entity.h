#pragma once
#include "box2d/box2d.h"
#include "SFML/Graphics.h"
typedef struct bwEntity {
	b2BodyId body;
	sfSprite* pSprite;
	float health;
	float timeLeft;
	bool explodeOnDeath;
} bwEntity;