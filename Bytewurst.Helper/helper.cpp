#include "helper.h"
#include "entity.h"
#include "SFML/Graphics.h"
#include <uchar.h>
#include <fstream>
#include <vector>
#include <filesystem>
#include <assert.h>

b2Vec2 launchVelocity = { 0,10.f };
b2Vec2 launchPos = { -5,2 };
float launchAngle = 1.f;
float launchPower = 10.f;
bool dragging = false;
sfVector2i lastMousePos;
sfSprite* sausageSprite = bwLoadSprite("img/sausage.png");

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

void drawTargetAssist(sfRenderWindow* pWindow, b2Vec2 pos, b2Vec2 launchVelocity, b2Vec2 gravity) {
	const float timeStep = 0.1f; // Time step for simulation
	const int maxSteps = 20; // Maximum number of steps to simulate
	sfColor color = sfColor_fromRGB(255, 0, 0);

	for (int i = 0; i < maxSteps; ++i) {
		// Calculate the position at the current time step
		b2Vec2 currentPos = pos + launchVelocity * timeStep * i + 0.5f * gravity * timeStep * timeStep * i * i;

		// Draw a point at the current position
		sfCircleShape* point = sfCircleShape_create();
		sfCircleShape_setRadius(point, 0.1f);
		sfCircleShape_setFillColor(point, color);
		sfCircleShape_setPosition(point, { currentPos.x, currentPos.y });
		sfRenderWindow_drawCircleShape(pWindow, point, NULL);
		sfCircleShape_destroy(point);
	}
}

b2BodyId CreateBox(b2WorldId world, b2Vec2 pos, b2Vec2 halfSize, float density) {
	b2BodyDef def = b2DefaultBodyDef();
	def.type = b2_dynamicBody;
	def.position = pos;
	b2BodyId body = b2CreateBody(world, &def);
	b2Polygon box = b2MakeBox(halfSize.x, halfSize.y);
	b2ShapeDef shapeDef = b2DefaultShapeDef();
	shapeDef.friction = 0.5f;
	shapeDef.density = density;
	shapeDef.restitution = 0.3f;
	shapeDef.enableContactEvents = true;
	b2CreatePolygonShape(body, &shapeDef, &box);
	return body;
}

void bwProcessEvents(bwWorldData* data) {
	sfEvent event;

	while (sfRenderWindow_pollEvent(data->pWindow, &event)) {
		switch (event.type)
		{
		case sfEvtKeyPressed:
			if (event.key.code == sfKeyRight) {
				launchAngle -= 0.01;
			}
			else if (event.key.code == sfKeyLeft) {
				launchAngle += 0.01;
			}
			else if (event.key.code == sfKeyUp) {
				launchPower += 0.05;
			}
			else if (event.key.code == sfKeyDown) {
				launchPower -= 0.05;
			}
			break;
		case sfEvtKeyReleased:
			if (event.key.code == sfKeySpace) {
				sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, lastMousePos, data->pView);
				b2BodyId body = CreateBox(data->worldId, { pos.x, pos.y }, { 2, 2 }, 1);
				bwEntity* pEntity = bwEntity_CreateDefault(data->pEntityPool, body);
				pEntity->explosionStrength = 5;
				pEntity->explosionParts = 20;
				pEntity->pSprite = sausageSprite;
				sfSprite_setScale(pEntity->pSprite, { -0.002, -0.002 });
				sfSprite_setOrigin(pEntity->pSprite, { 1024, 1024 });
			}
			else if (event.key.code == sfKeyEnter) {
				sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, lastMousePos, data->pView);
				b2BodyId body = CreateBox(data->worldId, { pos.x, pos.y }, { 2, 3 }, 1);
				bwEntity* pEntity = bwEntity_CreateDefault(data->pEntityPool, body);
				pEntity->pSprite = sausageSprite;
				sfSprite_setScale(pEntity->pSprite, { -0.002, -0.002 });
				sfSprite_setOrigin(pEntity->pSprite, { 1024, 1024 });
				b2Body_SetTransform(body, launchPos, b2Rot_identity);
				b2Body_SetLinearVelocity(body, launchVelocity);
			}
			break;
		case sfEvtMouseButtonPressed:
			event.mouseButton.x;
			printf("Mouse button pressed at %d %d\n", event.mouseButton.x, event.mouseButton.y);
			sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, { event.mouseButton.x, event.mouseButton.y }, data->pView);
			lastMousePos = { event.mouseButton.x, event.mouseButton.y };
			dragging = true;
			break;
		case sfEvtMouseButtonReleased:
			dragging = false;
			break;
		case sfEvtMouseMoved:
			if (dragging) {
				sfVector2i deltaOrg = { lastMousePos.x - event.mouseMove.x ,lastMousePos.y - event.mouseMove.y };
				sfVector2f viewSize = sfView_getSize(data->pView);
				sfVector2u windowSize = sfRenderWindow_getSize(data->pWindow);
				sfVector2f delta = { deltaOrg.x * viewSize.x / windowSize.x, deltaOrg.y * viewSize.y / windowSize.y };
				sfView_move(data->pView, delta);
			}
			lastMousePos = { event.mouseMove.x, event.mouseMove.y };
			break;
		case sfEvtMouseWheelScrolled:
			sfVector2f viewSize = sfView_getSize(data->pView);
			viewSize.x *= 1 - 0.1 * event.mouseWheelScroll.delta;
			viewSize.y *= 1 - 0.1 * event.mouseWheelScroll.delta;
			sfView_setSize(data->pView, viewSize);
			event.mouseWheelScroll.delta;
			break;
		default:
			break;
		}
	}
	// Contact events
	b2ContactEvents events = b2World_GetContactEvents(data->worldId);
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
	bwEntity_UpdateAll(data);

	launchVelocity.x = launchPower * cos(launchAngle);
	launchVelocity.y = launchPower * sin(launchAngle);
	drawTargetAssist(data->pWindow, launchPos, launchVelocity, b2World_GetGravity(data->worldId));
}