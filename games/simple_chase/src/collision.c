#include "include/chipcade.h"

extern unsigned char player_x;
extern unsigned char player_y;
extern unsigned char target_x;
extern unsigned char target_y;
extern unsigned char collided;

void CheckCollision() {
    if (player_x + 7 >= target_x) {
        if (target_x + 7 >= player_x) {
            if (player_y + 7 >= target_y) {
                if (target_y + 7 >= player_y) {
                    collided = 1;
                    return;
                }
            }
        }
    }
    collided = 0;
}
