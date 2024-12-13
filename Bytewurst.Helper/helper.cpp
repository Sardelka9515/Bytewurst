#include "helper.h"
#include "entity.h"
#include "SFML/Graphics.h"
#include <uchar.h>
#include <fstream>
#include <vector>
#include <filesystem>
#include <assert.h>
#include <cmath>

const char* fontPath = "C:\\Windows\\fonts\\arial.ttf";
sfFont* font = sfFont_createFromFile(fontPath);
sfText* text = NULL;
b2Vec2 launchVelocity = { 0,0 };
b2Vec2 launchPos = { -90,2 };
bool dragging = false;
bool launching = false;
sfVector2i lastMousePos;
sfSprite* sausageSprite = bwLoadSprite("img/sausage.png");
sfSprite* kitchenSprite = bwLoadSprite("img/kitchen.png");
float maxLaunchPower = 50;
float minLaunchPower = 5;

void clampLaunchVelocity() {
	float velocityLength = sqrt(launchVelocity.x * launchVelocity.x + launchVelocity.y * launchVelocity.y);
	if (velocityLength > maxLaunchPower) {
		float scale = maxLaunchPower / velocityLength;
		launchVelocity.x *= scale;
		launchVelocity.y *= scale;
	}
}

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

	sfVector2u dimension = sfTexture_getSize(texture);
	sfSprite* pSprite = sfSprite_create();
	sfSprite_setTexture(pSprite, texture, 1);
	sfSprite_setOrigin(pSprite, { dimension.x / 2.f, dimension.y / 2.f });
	return pSprite;
}

sfColor HexToColor(b2HexColor color) {
	return sfColor_fromRGBA((color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF, 127);
}

void bwDrawSolidCapsule(b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context) {
	sfRenderWindow* pWindow = (sfRenderWindow*)context;
	// Draw the circles
	sfCircleShape* circle = sfCircleShape_create();
	sfCircleShape_setRadius(circle, radius);
	sfCircleShape_setPosition(circle, { p1.x - radius, p1.y - radius });
	sfCircleShape_setFillColor(circle, HexToColor(color));
	sfRenderWindow_drawCircleShape(pWindow, circle, NULL);

	sfCircleShape_setRadius(circle, radius);
	sfCircleShape_setPosition(circle, { p2.x - radius, p2.y - radius });
	sfCircleShape_setFillColor(circle, HexToColor(color));
	sfRenderWindow_drawCircleShape(pWindow, circle, NULL);
	sfCircleShape_destroy(circle);
}

void drawTargetAssist(sfRenderWindow* pWindow, b2Vec2 pos, b2Vec2 launchVelocity, b2Vec2 gravity) {
	const float timeStep = 0.3f; // Time step for simulation
	const int maxSteps = 20; // Maximum number of steps to simulate
	sfColor color = sfColor_fromRGB(255, 255, 255);
	for (int i = 0; i < maxSteps; ++i) {
		sfCircleShape* point = sfCircleShape_create();
		// Calculate the position at the current time step
		b2Vec2 currentPos = pos + launchVelocity * timeStep * i + 0.5f * gravity * timeStep * timeStep * i * i;

		// Draw a point at the current position
		const float radius = 0.5f;
		sfCircleShape_setRadius(point, radius);
		sfCircleShape_setFillColor(point, color);
		sfCircleShape_setOutlineColor(point, { 0,0,0,255 });
		sfCircleShape_setOutlineThickness(point, 0.1);
		sfCircleShape_setPosition(point, { currentPos.x - radius, currentPos.y - radius });
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

b2BodyId CreateCapsule(b2WorldId world, b2Vec2 pos, float height, float radius, float density) {
	b2BodyDef def = b2DefaultBodyDef();
	def.type = b2_dynamicBody;
	def.position = pos;
	b2BodyId body = b2CreateBody(world, &def);
	b2ShapeDef shapeDef = b2DefaultShapeDef();
	shapeDef.friction = 0.5f;
	shapeDef.density = density;
	shapeDef.restitution = 0.3f;
	shapeDef.enableContactEvents = true;
	b2Capsule capule;
	capule.center1 = { 0,height / -2 };
	capule.center2 = { 0,height / 2 };
	capule.radius = radius;
	b2CreateCapsuleShape(body, &shapeDef, &capule);
	return body;
}

void drawText(bwWorldData* data, b2Vec2 pos, const char* str) {
	sfText_setPosition(text, { pos.x, pos.y });
	sfText_setString(text, str);
	float scale = abs(sfView_getSize(data->pView).y / 2000);
	sfText_setScale(text, { scale, -scale });
	sfRenderWindow_drawText(data->pWindow, text, data->pRenderStates);
}

void Setup(bwWorldData* data) {
	text = sfText_create();
	sfText_setFont(text, font);
	sfText_setCharacterSize(text, 50);
	sfText_setFillColor(text, sfColor_fromRGB(255, 255, 255));
	sfText_setPosition(text, { 0, 0 });
	drawText(data, { 0,0 }, "Hello");
	sfSprite_scale(kitchenSprite, { 0.1, -0.1 });
	sfSprite_setPosition(kitchenSprite, { 0,35 });
}

bwEntity* CreateSausage(bwWorldData* data, b2Vec2 pos, b2Rot rot) {
	b2BodyId body = CreateCapsule(data->worldId, pos, 2.2, 1.4, 1);
	bwEntity* pEntity = bwEntity_CreateDefault(data->pEntityPool, body);
	pEntity->pSprite = sausageSprite;
	sfSprite_setScale(pEntity->pSprite, { -0.02, -0.02 });
	b2Body_SetTransform(body, pos, rot);
	return pEntity;
}
sfVector2f scalePixelToCoords(sfRenderWindow* pWindow, sfVector2i pixel, sfView* pView) {
	sfVector2f viewSize = sfView_getSize(pView);
	sfVector2u windowSize = sfRenderWindow_getSize(pWindow);
	sfVector2f delta = { pixel.x * viewSize.x / windowSize.x, pixel.y * viewSize.y / windowSize.y };
	return { delta.x, delta.y };
}
b2Vec2 launchStart;
void launchSasusage(bwWorldData* data) {
	float launchAngle = b2Atan2(launchVelocity.y, launchVelocity.x);
	b2Rot rot = { cos(launchAngle),sin(launchAngle) };
	bwEntity* pSasusage = CreateSausage(data, launchPos, rot);
	b2Body_SetLinearVelocity(pSasusage->body, launchVelocity);
	b2Body_ApplyAngularImpulse(pSasusage->body, -50, true);
}
void bwProcessEvents(bwWorldData* data) {

	if (!text) {
		Setup(data);
	}

	sfEvent event;

	while (sfRenderWindow_pollEvent(data->pWindow, &event)) {
		switch (event.type)
		{
		case sfEvtKeyPressed:/*
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
			}*/
			break;
		case sfEvtKeyReleased:
			if (event.key.code == sfKeySpace) {
				sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, lastMousePos, data->pView);
				b2BodyId body = CreateBox(data->worldId, { pos.x, pos.y }, { 2, 2 }, 1);
				bwEntity* pEntity = bwEntity_CreateDefault(data->pEntityPool, body);
				pEntity->explosionStrength = 5;
				pEntity->explosionParts = 20;
				pEntity->pSprite = sausageSprite;
				sfSprite_setScale(pEntity->pSprite, { -0.02, -0.02 });
			}
			break;
		case sfEvtMouseButtonPressed:
			sfVector2f coord = sfRenderWindow_mapPixelToCoords(data->pWindow, { event.mouseButton.x, event.mouseButton.y }, data->pView);
			printf("%d, %d => %f, %f\n", event.mouseButton.x, event.mouseButton.y, coord.x, coord.y);
			sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, { event.mouseButton.x, event.mouseButton.y }, data->pView);
			lastMousePos = { event.mouseButton.x, event.mouseButton.y };
			if (event.mouseButton.button == sfMouseLeft) {
				launching = true;
				launchStart = *(b2Vec2*)&pos;
			}
			else if (event.mouseButton.button == sfMouseRight) {
				dragging = true;
			}
			break;
		case sfEvtMouseButtonReleased:
			if (event.mouseButton.button == sfMouseLeft) {

				float velocityLength = sqrt(launchVelocity.x * launchVelocity.x + launchVelocity.y * launchVelocity.y);
				if (velocityLength >= minLaunchPower) {
					launchSasusage(data);
				}
				launching = false;
			}
			else if (event.mouseButton.button == sfMouseRight) {
				dragging = false;
			}
			break;
		case sfEvtMouseMoved:
			if (dragging) {
				sfVector2i deltaOrg = { lastMousePos.x - event.mouseMove.x ,lastMousePos.y - event.mouseMove.y };
				sfVector2f delta = scalePixelToCoords(data->pWindow, deltaOrg, data->pView);
				sfView_move(data->pView, delta);
			}
			else if (launching) {
				sfVector2f pos = sfRenderWindow_mapPixelToCoords(data->pWindow, { event.mouseMove.x, event.mouseMove.y }, data->pView);
				launchVelocity = -(*(b2Vec2*)&pos - launchStart);
				clampLaunchVelocity();
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


	// Draw background
	sfRenderWindow_drawSprite(data->pWindow, kitchenSprite, data->pRenderStates);

	bwEntity_UpdateAll(data);

	if (launching && sqrt(launchVelocity.x * launchVelocity.x + launchVelocity.y * launchVelocity.y) >= minLaunchPower) {
		drawTargetAssist(data->pWindow, launchPos, launchVelocity, b2World_GetGravity(data->worldId));
	}
}