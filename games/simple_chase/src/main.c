#include "include/chipcade.h"

unsigned char player_x;
unsigned char player_y;
unsigned char target_x;
unsigned char target_y;
unsigned char target_dx;
unsigned char target_dy;
unsigned char score;
unsigned char flash;
unsigned char reset_timer;
unsigned char collided;

void CheckCollision();

void SetSprites() {
    unsigned char player_col;

    player_col = score;
    if (player_col >= 16) {
        player_col = 15;
    }

    sprite[0].x = player_x;
    sprite[0].y = player_y;
    sprite[0].tile = SPR_CHIPCADE;
    sprite[0].flags = 0x10;
    sprite[0].c0 = player_col;
    sprite[0].c1 = 7;
    sprite[0].c2 = 15;
    sprite[0].reserved = 0;

    sprite[1].x = target_x;
    sprite[1].y = target_y;
    sprite[1].tile = SPR_CHIPCADE;
    sprite[1].flags = 0x10;
    if (flash >= 6) {
        sprite[1].c0 = 2;
        sprite[1].c1 = 10;
        sprite[1].c2 = 15;
    }
    else {
        sprite[1].c0 = 12;
        sprite[1].c1 = 5;
        sprite[1].c2 = 15;
    }
    sprite[1].reserved = 0;
}

void Init() {
    player_x = 0x20;
    player_y = 0x20;
    target_x = 0xC0;
    target_y = 0x90;
    target_dx = 0;
    target_dy = 0;
    score = 0;
    flash = 0;
    reset_timer = 0;
    collided = 0;
    SetSprites();
}

void Update() {
    if (reset_timer > 0) {
        reset_timer--;
        if (reset_timer == 0) {
            player_x = 0x20;
            player_y = 0x20;
            target_x = 0xC0;
            target_y = 0x90;
            target_dx = 0;
            target_dy = 0;
        }
        SetSprites();
        return;
    }

    if (mem[IO_LEFT] != 0) {
        if (player_x > 0x10) {
            player_x--;
        }
    }
    if (mem[IO_RIGHT] != 0) {
        if (player_x < 0xE8) {
            player_x++;
        }
    }
    if (mem[IO_UP] != 0) {
        if (player_y > 0x18) {
            player_y--;
        }
    }
    if (mem[IO_DOWN] != 0) {
        if (player_y < 0xB0) {
            player_y++;
        }
    }

    if (target_dx == 0) {
        target_x++;
        if (target_x >= 0xE8) {
            target_dx = 1;
        }
    }
    else {
        target_x--;
        if (target_x <= 0x10) {
            target_dx = 0;
        }
    }

    if (target_dy == 0) {
        target_y++;
        if (target_y >= 0xB0) {
            target_dy = 1;
        }
    }
    else {
        target_y--;
        if (target_y <= 0x18) {
            target_dy = 0;
        }
    }

    CheckCollision();
    if (collided != 0) {
        score++;
        flash = 12;
        reset_timer = 18;
    }

    if (flash > 0) {
        flash--;
    }

    SetSprites();
}
