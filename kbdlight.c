#include <stdio.h>
#include <string.h>

#define SYSFS "/sys/class/leds/tpacpi::kbd_backlight/brightness"

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <0|1|2>\n", argv[0]);
        return 1;
    }

    if (strcmp(argv[1], "0") != 0 &&
        strcmp(argv[1], "1") != 0 &&
        strcmp(argv[1], "2") != 0) {
        fprintf(stderr, "Brightness must be 0, 1, or 2.\n");
        return 1;
    }

    FILE *file = fopen(SYSFS, "w");
    if (file == NULL) {
        perror("Unable to open ThinkPad keyboard backlight interface");
        return 1;
    }

    if (fputs(argv[1], file) == EOF || fclose(file) == EOF) {
        perror("Unable to set ThinkPad keyboard backlight");
        return 1;
    }

    return 0;
}
