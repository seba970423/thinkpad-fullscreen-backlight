#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SYSFS "/sys/class/leds/tpacpi::kbd_backlight/brightness"

int main(int argc, char **argv)
{
    if (argc != 2)
        return 1;

    if (strcmp(argv[1], "0") &&
        strcmp(argv[1], "1") &&
        strcmp(argv[1], "2"))
        return 1;

    FILE *f = fopen(SYSFS, "w");
    if (!f)
        return 1;

    fputs(argv[1], f);
    fclose(f);

    return 0;
}
