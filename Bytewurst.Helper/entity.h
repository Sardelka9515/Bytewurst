#pragma once
#include "box2d/box2d.h"
#include "SFML/Graphics.h"
#include "pool.h"
#include "bw.h"

typedef struct bwEntity {
	b2BodyId body;
	sfSprite* pSprite;
	float health;
	float timeLeft;
	float explosionStrength;
	uint32_t explosionParts;
	size_t index;
	bwPool* pPool;
} bwEntity;

BW_EXPORT bwEntity* bwEntity_CreateDefault(bwPool* pPool, b2BodyId body);

BW_EXPORT bwEntity* bwEntity_CreateParticle(bwPool* pPool, b2WorldId world, b2Vec2 pos, float lifeSpan);

BW_EXPORT void bwEntity_Destroy(bwEntity* entity);

BW_EXPORT void bwEntity_ApplyDamage(bwEntity* entity, float damage);

BW_EXPORT void bwEntity_Update(bwEntity* entity, float dt, sfRenderWindow* pWindow, sfRenderStates* pRenderState);

BW_EXPORT void bwEntity_UpdateAll(bwPool* pPool, float dt, sfRenderWindow* pWindow, sfRenderStates* pRenderStates);

BW_EXPORT bwEntity* bwEntity_GetFromBody(b2BodyId body);

BW_EXPORT void bwEntity_Validate(bwEntity* entity);

BW_EXPORT void bwEntity_Kill(bwEntity* entity);