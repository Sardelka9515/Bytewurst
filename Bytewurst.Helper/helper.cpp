#include "helper.h"
#include "entity.h"
#include "SFML/Graphics.h"
#include <uchar.h>
#include <fstream>
#include <vector>
#include <filesystem>
#include <assert.h>

sfSprite* bwLoadSprite(const char* path) {
	// print curent working directory
	wprintf(L"%s", std::filesystem::current_path().c_str());

	// load file data from path
	std::ifstream file(path, std::ios::binary | std::ios::ate);
	if (!file.is_open()) {
		return nullptr;
	}

	std::streamsize size = file.tellg();
	file.seekg(0, std::ios::beg);

	std::vector<char> buffer(size);
	if (!file.read(buffer.data(), size)) {
		return nullptr;
	}

	sfTexture* texture = sfTexture_createFromMemory(buffer.data(), buffer.size(), NULL);
	if (!texture) {
		return nullptr;
	}

	sfSprite* pSprite = sfSprite_create();
	sfSprite_setTexture(pSprite, texture, 1);
	return pSprite;
}


void bwProcessEvents(sfRenderWindow* pWindow, sfView* pView, sfEvent event, b2WorldId worldId) {

	switch (event.type)
	{
	case sfEvtMouseButtonPressed:
		event.mouseButton.x;
		printf("Mouse button pressed at %d %d\n", event.mouseButton.x, event.mouseButton.y);
		sfVector2f pos = sfRenderWindow_mapPixelToCoords(pWindow, { event.mouseButton.x, event.mouseButton.y }, pView);
		// b2World_OverlapPoint(worldId, *(b2Vec2*)&pos, b2Transform_identity, b2DefaultQueryFilter(), , );
		break;
	case sfEvtMouseButtonReleased:
		break;
	case sfEvtMouseMoved:
		break;
	case sfEvtMouseWheelScrolled:
		sfVector2f viewSize = sfView_getSize(pView);
		viewSize.x *= 1 - 0.1 * event.mouseWheelScroll.delta;
		viewSize.y *= 1 - 0.1 * event.mouseWheelScroll.delta;
		sfView_setSize(pView, viewSize);
		event.mouseWheelScroll.delta;
		break;
	default:
		break;
	}
	// Contact events
	b2ContactEvents events = b2World_GetContactEvents(worldId);
	for (int i = 0; i < events.beginCount; i++) {
		b2ContactBeginTouchEvent e = events.beginEvents[i];
		assert((b2Shape_IsValid(e.shapeIdA) && b2Shape_IsValid(e.shapeIdB)));
		b2BodyId a = b2Shape_GetBody(e.shapeIdA);
		b2BodyId b = b2Shape_GetBody(e.shapeIdB);
		bwEntity* pA = bwEntity_GetFromBody(a);
		bwEntity* pB = bwEntity_GetFromBody(b);
		if (pA) {
			bwEntity_Validate(pA);
			if (pA->explosionStrength > 0) {
				bwEntity_Kill(pA);
			}
		}
		if (pB) {
			bwEntity_Validate(pB);
			if (pB->explosionStrength > 0) {
				bwEntity_Kill(pB);
			}
		}
	}
}