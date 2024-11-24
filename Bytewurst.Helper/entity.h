#pragma once
#include "box2d/box2d.h"
#include "SFML/Graphics.h"
#include "pool.h"

typedef struct bwEntity {
	b2BodyId body;
	sfSprite* pSprite;
	float health;
	float timeLeft;
	float explosionStrength;
	int explosionParts;
	size_t index;
	bwPool* pPool;
} bwEntity;

bwEntity* bwEntity_CreateParticle(bwPool* pPool,b2WorldId world, b2Vec2 pos, float lifeSpan);

void bwEntity_Destroy(bwEntity* entity);

void bwEntity_ApplyDamage(bwEntity* entity, float damage);

void bwEntity_Update(bwEntity* entity, float dt, sfRenderWindow* pWindow, sfRenderStates* pRenderState);