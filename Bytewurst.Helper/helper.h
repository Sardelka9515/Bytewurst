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


BW_EXPORT sfSprite* bwLoadSprite(const char* path);
BW_EXPORT void bwProcessEvents(bwWorldData* data);