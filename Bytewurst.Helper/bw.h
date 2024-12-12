#pragma once
#ifdef __cplusplus
	#define BW_EXPORT extern "C" 
#else
	#define BW_EXPORT
#endif
#include <stdint.h>
#include <stdlib.h>
#include <SFML/Graphics.h>
#include <box2d/box2d.h>
