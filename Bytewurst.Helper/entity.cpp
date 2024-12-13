// Bytewurst.Helper.cpp : Defines the functions for the static library.
//

#include "entity.h"
#include "box2d/box2d.h"
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include "helper.h"
#include "stdio.h"

typedef struct bwEntityInfo {
	bwPool* pPool;
	size_t index;
} bwEntityInfo;

float RandomFloat(float min, float max) {
	return ((float)rand() / RAND_MAX) * (max - min) + min;
}

void bwEntity_Validate(bwEntity* e) {
	assert(e->pPool);
	assert(e->index < e->pPool->size);
	assert(e->pPool->elementSize == sizeof(bwEntity));
	assert(e == (bwEntity*)bwPool_Get(e->pPool, e->index));
}

bwEntity* bwEntity_CreateDefault(bwPool* pPool, b2BodyId body) {
	size_t index = bwPool_Add(pPool);
	bwEntity entity = { 0 };
	entity.body = body;
	entity.health = -1;
	entity.timeLeft = -1;
	entity.pSprite = NULL;
	entity.explosionParts = 0;
	entity.explosionStrength = 0;
	entity.pPool = pPool;
	entity.index = index;
	bwEntity* pEntity = (bwEntity*)bwPool_Get(pPool, index);
	*pEntity = entity;
	// Ew
	bwEntityInfo* pInfo = (bwEntityInfo*)malloc(sizeof(bwEntityInfo));
	if (pInfo) {
		pInfo->pPool = pPool;
		pInfo->index = index;
	}
	else {
		__debugbreak();
	}
	b2Body_SetUserData(body, pInfo);
	return pEntity;
}

bwEntity* bwEntity_CreateParticle(bwPool* pPool, b2WorldId world, b2Vec2 pos, float lifeSpan) {
	b2BodyDef def = b2DefaultBodyDef();
	def.type = b2_dynamicBody;
	def.position = pos;
	b2BodyId body = b2CreateBody(world, &def);
	b2Polygon box = b2MakeBox(RandomFloat(0.2, 0.7), RandomFloat(0.2, 0.7));
	b2ShapeDef shapeDef = b2DefaultShapeDef();
	shapeDef.friction = 0.5f;
	shapeDef.density = 1.0f;
	shapeDef.restitution = 0.3f;
	b2CreatePolygonShape(body, &shapeDef, &box);
	bwEntity* pEntity = bwEntity_CreateDefault(pPool, body);
	pEntity->timeLeft = lifeSpan;
	return pEntity;
}

// Kill entity, doesn't destroy it immediately but will destroy it on the next update
void bwEntity_Kill(bwEntity* entity) {
	entity->timeLeft = 0;
	entity->health = 0;
}

void bwEntity_Destroy(bwEntity* entity) {
	// Ew
	bwEntityInfo* pInfo = (bwEntityInfo*)b2Body_GetUserData(entity->body);
	b2Body_SetUserData(entity->body, NULL);
	free(pInfo);
	if (entity->explosionStrength > 0) {
		b2ExplosionDef def = b2DefaultExplosionDef();
		def.falloff = entity->explosionStrength / 2;
		def.impulsePerLength = entity->explosionStrength * 3;
		def.radius = entity->explosionStrength;
		def.position = b2Body_GetPosition(entity->body);
		b2AABB region = b2Body_ComputeAABB(entity->body);
		// Create random explosion parts
		for (uint32_t i = 0; i < entity->explosionParts; i++) {
			b2Vec2 pos;
			pos.x = RandomFloat(region.lowerBound.x, region.upperBound.x);
			pos.y = RandomFloat(region.lowerBound.y, region.upperBound.y);
			bwEntity_CreateParticle(entity->pPool, b2Body_GetWorld(entity->body), pos, RandomFloat(3, 6));
		}
		b2WorldId world = b2Body_GetWorld(entity->body);
		b2DestroyBody(entity->body);
		bwPool_Remove(entity->pPool, entity->index);
		b2World_Explode(world, &def);
	}
	else {
		b2DestroyBody(entity->body);
		bwPool_Remove(entity->pPool, entity->index);
	}
}

void bwEntity_ApplyDamage(bwEntity* entity, float damage) {
	if (entity->health == -1) {
		return;
	}
	entity->health -= damage;
	if (entity->health <= 0) {
		bwEntity_Kill(entity);
	}
}

void bwEntity_Update(bwEntity* entity, bwWorldData* data) {
	bwEntity_Validate(entity);
	if (entity->timeLeft != -1) {
		entity->timeLeft -= data->timeStep;
		if (entity->timeLeft <= 0) {
			bwEntity_Destroy(entity);
			return;
		}
	}
	if (entity->health != -1 && entity->health <= 0) {
		bwEntity_Destroy(entity);
		return;
	}
	b2Transform transform = b2Body_GetTransform(entity->body);
	if (entity->pSprite) {
		float degress = b2Atan2(transform.q.s, transform.q.c) * 180 / b2_pi;
		sfSprite_setPosition(entity->pSprite, *(sfVector2f*)&transform.p);
		sfSprite_setRotation(entity->pSprite, degress);
		sfRenderWindow_drawSprite(data->pWindow, entity->pSprite, data->pRenderStates);
	}

	if (entity->health != -1) {
		char str[100];
		snprintf(str, sizeof(str), "Health: %f", entity->health);
		bwDrawText(data, transform.p, str);
	}
}

void bwEntity_UpdateAll(bwWorldData* data) {
	size_t newSize = 0;
	for (size_t i = 0; i < data->pEntityPool->size; i++) {
		bwEntity* pEntity = (bwEntity*)bwPool_Get(data->pEntityPool, i);
		if (*(uint64_t*)&pEntity->body == 0) {
			continue;
		}
		newSize = i;
		bwEntity_Update(pEntity, data);
	}
	newSize += 1;
	if (data->pEntityPool->size > newSize) {
		bwPool_Truncate(data->pEntityPool, newSize);
	}
}

bwEntity* bwEntity_GetFromBody(b2BodyId body) {
	bwEntityInfo* pInfo = (bwEntityInfo*)b2Body_GetUserData(body);
	if (!pInfo) {
		return NULL;
	}
	bwEntity* result = (bwEntity*)bwPool_Get(pInfo->pPool, pInfo->index);
	return result;
}