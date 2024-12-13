#pragma once
#include "box2d/box2d.h"
#include "SFML/Graphics.h"
#include "pool.h"
#include "bw.h"
#include "helper.h"

typedef struct bwEntity {
	b2BodyId body;
	sfSprite* pSprite;
	float health;
	float timeLeft;
	// How much impulse it can withstand before taking damage
	float hardness;
	float explosionStrength;
	uint32_t explosionParts;
	size_t index;
	bwPool* pPool;
} bwEntity;

BW_EXPORT bwEntity* bwEntity_CreateDefault(bwPool* pPool, b2BodyId body);

BW_EXPORT bwEntity* bwEntity_CreateParticle(bwPool* pPool, b2WorldId world, b2Vec2 pos, float lifeSpan);

BW_EXPORT void bwEntity_Destroy(bwEntity* entity);

BW_EXPORT void bwEntity_ApplyDamage(bwEntity* entity, float damage);

BW_EXPORT void bwEntity_Update(bwEntity* entity,bwWorldData* data);

BW_EXPORT void bwEntity_UpdateAll(bwWorldData* data);

BW_EXPORT bwEntity* bwEntity_GetFromBody(b2BodyId body);

BW_EXPORT void bwEntity_Validate(bwEntity* entity);

BW_EXPORT void bwEntity_Kill(bwEntity* entity);