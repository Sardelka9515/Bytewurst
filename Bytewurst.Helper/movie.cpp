#pragma once

#include "movie.h"
#include <iostream>
#include <filesystem>

namespace fs = std::filesystem;

extern "C" sfSprite** bwMovie_Load(const char* dir, size_t* count) {
    std::string path(dir);
    std::vector<sfTexture*> textures;
    for (const auto& entry : fs::directory_iterator(path)) {
        textures.push_back(sfTexture_createFromFile(entry.path().string().c_str(), NULL));
    }

	sfSprite** sprites = (sfSprite**)malloc(textures.size() * sizeof(sfSprite*));
	if (!sprites) {
		std::cerr << "Failed to allocate memory for sprites." << std::endl;
		return NULL;
	}
	for (int i = 0; i < textures.size(); i++) {
		sprites[i] = sfSprite_create();
		sfSprite_setTexture(sprites[i], textures[i], true);
	}
	*count = textures.size();
	return sprites;
}