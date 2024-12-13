#pragma once
#include <SFML/Graphics.h>
#include <box2d/box2d.h>
#include "bw.h"
#include "pool.h"

typedef struct bwWorldData {
	float timeStep;
	b2WorldId worldId;
	sfRenderWindow* pWindow;
	sfView* pView;
	sfRenderStates* pRenderStates;
	bwPool* pEntityPool;
	bwPool* pParticlePool;
} bwWorldData;

typedef struct bwLevel
{
	int regularSasusages;
	int explosiveSasusages;
	void (*bwLevelUpdate)(bwWorldData* data);
	void (*bwLevelInit)(bwWorldData* data);
} bwLevel;

BW_EXPORT sfSprite* bwLoadSprite(const char* path);
BW_EXPORT void bwProcessEvents(bwWorldData* data);
BW_EXPORT void bwDrawSolidCapsule(b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context);
BW_EXPORT void bwDrawText(bwWorldData* data, b2Vec2 pos, char* str);