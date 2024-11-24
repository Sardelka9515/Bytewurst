// Bytewurst.Helper.cpp : Defines the functions for the static library.
//

#include "entity.h"
#include "box2d/box2d.h"
#include <stdlib.h>
#include <string.h>

float RandomFloat(float min, float max) {
	return ((float)rand() / RAND_MAX) * (max - min) + min;
}

bwEntity bwEntity_CreateParticle(b2WorldId world, b2Vec2 pos, float lifeSpan) {
	b2BodyDef def = b2DefaultBodyDef();
	def.type = b2_kinematicBody;
	def.position = pos;
	b2BodyId body = b2CreateBody(world, &def);
	b2Polygon box = b2MakeBox(1, 1);
	b2ShapeDef shapeDef = b2DefaultShapeDef();
	shapeDef.friction = 0.5f;
	shapeDef.density = 0.5f;
	shapeDef.restitution = 0.5f;
	b2CreatePolygonShape(body, &shapeDef, &box);
	bwEntity entity = { 0 };
	entity.body = body;
	entity.timeLeft = lifeSpan;
	entity.pSprite = NULL;
	return entity;
}

void bwEntity_Destroy(bwEntity* entity) {
	if (entity->explosionStrength > 0) {
		b2ExplosionDef def = b2DefaultExplosionDef();
		def.falloff = entity->explosionStrength / 2;
		def.impulsePerLength = entity->explosionStrength * 3;
		def.radius = entity->explosionStrength;
		def.position = b2Body_GetPosition(entity->body);
		b2AABB region = b2Body_ComputeAABB(entity->body);
		// Create random explosion parts
		for (int i = 0; i < entity->explosionParts; i++) {
			b2Vec2 pos;
			pos.x = RandomFloat(region.lowerBound.x, region.upperBound.x);
			pos.y = RandomFloat(region.lowerBound.y, region.upperBound.y);
			bwEntity_CreateParticle(b2Body_GetWorld(entity->body), pos, 1);
		}
		b2WorldId world = b2Body_GetWorld(entity->body);
		b2DestroyBody(entity->body);
		memset(entity, 0, sizeof(bwEntity));
		b2World_Explode(world, &def);
	}
}

void bwEntity_ApplyDamage(bwEntity* entity, float damage) {
	if (entity->health == -1) {
		return;
	}
	entity->health -= damage;
	if (entity->health <= 0) {
		bwEntity_Destroy(entity);
	}
}

void bwEntity_Update(bwEntity* entity, float dt, sfRenderWindow* pWindow, sfRenderStates* pRenderStates) {
	if (entity->timeLeft != -1) {
		entity->timeLeft -= dt;
		if (entity->timeLeft <= 0) {
			bwEntity_Destroy(entity);
			return;
		}
	}
	if (entity->pSprite) {
		b2Transform transform = b2Body_GetTransform(entity->body);
		float degress = b2Atan2(transform.q.s, transform.q.c) * 180 / b2_pi;
		sfSprite_setPosition(entity->pSprite, *(sfVector2f*)&transform.p);
		sfSprite_setRotation(entity->pSprite, degress);
		sfRenderWindow_drawSprite(pWindow, entity->pSprite, pRenderStates);
	}
}
