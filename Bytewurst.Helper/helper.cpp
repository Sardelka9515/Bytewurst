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


void bwProcessEvents(b2WorldId worldId) {
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
