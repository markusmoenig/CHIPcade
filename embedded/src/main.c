#include "include/chipcade.h"

unsigned char spr_pos_x;
unsigned char spr_frame;
unsigned char spr_dir;

void SetSprite() {
    sprite[0].x = spr_pos_x;
    sprite[0].y = 0x50;
    sprite[0].tile = SPR_CHIPCADE;
    sprite[0].flags = 0x10;  // enable + 8x8
    sprite[0].c0 = 12;
    sprite[0].c1 = 7;
    sprite[0].c2 = 15;
    sprite[0].reserved = 0;
}

void Init() {
    spr_pos_x = 0x20;
    spr_frame = 0;
    spr_dir = 0;
    SetSprite();
}

void Update() {
    if (spr_dir == 0) {
        spr_pos_x++;
        if (spr_pos_x >= 0xDC) {
            spr_dir = 1;
        }
    }
    else {
        spr_pos_x--;
        if (spr_pos_x <= 0x10) {
            spr_dir = 0;
        }
    }

    spr_frame++;
    SetSprite();
}
