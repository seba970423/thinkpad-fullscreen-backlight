#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <pwd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#define SYSFS_BRIGHTNESS "/sys/class/leds/tpacpi::kbd_backlight/brightness"
#define STATE_FILENAME "thinkpad-fullscreen-backlight.state"

static int read_brightness(void)
{
    FILE *file = fopen(SYSFS_BRIGHTNESS, "r");
    int value;

    if (file == NULL) {
        perror("Unable to open ThinkPad keyboard backlight interface");
        return -1;
    }

    if (fscanf(file, "%d", &value) != 1 || value < 0 || value > 2) {
        fprintf(stderr, "Unable to read a valid keyboard brightness.\n");
        fclose(file);
        return -1;
    }

    if (fclose(file) != 0) {
        perror("Unable to close keyboard backlight interface");
        return -1;
    }

    return value;
}

static int write_brightness(int value)
{
    FILE *file;

    if (value < 0 || value > 2) {
        fprintf(stderr, "Brightness must be 0, 1, or 2.\n");
        return -1;
    }

    file = fopen(SYSFS_BRIGHTNESS, "w");
    if (file == NULL) {
        perror("Unable to open ThinkPad keyboard backlight interface");
        return -1;
    }

    if (fprintf(file, "%d\n", value) < 0 || fclose(file) != 0) {
        perror("Unable to set ThinkPad keyboard backlight");
        return -1;
    }

    return 0;
}

static int state_path(char *buffer, size_t size)
{
    uid_t uid = getuid();
    int written = snprintf(buffer, size, "/run/user/%lu/%s",
                           (unsigned long)uid, STATE_FILENAME);

    if (written < 0 || (size_t)written >= size) {
        fprintf(stderr, "Unable to build state-file path.\n");
        return -1;
    }

    return 0;
}

static int save_state(int value)
{
    char path[PATH_MAX];
    char data[4];
    int fd;
    int length;

    if (state_path(path, sizeof(path)) != 0)
        return -1;

    fd = open(path, O_WRONLY | O_CREAT | O_TRUNC | O_CLOEXEC | O_NOFOLLOW, 0600);
    if (fd < 0) {
        perror("Unable to create keyboard-backlight state file");
        return -1;
    }

    if (fchown(fd, getuid(), getgid()) != 0) {
        perror("Unable to set state-file ownership");
        close(fd);
        return -1;
    }

    length = snprintf(data, sizeof(data), "%d\n", value);
    if (length < 0 || write(fd, data, (size_t)length) != length) {
        perror("Unable to save keyboard-backlight state");
        close(fd);
        return -1;
    }

    if (close(fd) != 0) {
        perror("Unable to close keyboard-backlight state file");
        return -1;
    }

    return 0;
}

static int load_state(void)
{
    char path[PATH_MAX];
    char data[8] = {0};
    char *end = NULL;
    long value;
    int fd;
    ssize_t count;

    if (state_path(path, sizeof(path)) != 0)
        return -1;

    fd = open(path, O_RDONLY | O_CLOEXEC | O_NOFOLLOW);
    if (fd < 0) {
        if (errno == ENOENT)
            return read_brightness();
        perror("Unable to open keyboard-backlight state file");
        return -1;
    }

    count = read(fd, data, sizeof(data) - 1);
    if (count < 0) {
        perror("Unable to read keyboard-backlight state");
        close(fd);
        return -1;
    }

    if (close(fd) != 0) {
        perror("Unable to close keyboard-backlight state file");
        return -1;
    }

    errno = 0;
    value = strtol(data, &end, 10);
    if (errno != 0 || end == data || value < 0 || value > 2) {
        fprintf(stderr, "Saved keyboard-backlight state is invalid.\n");
        return -1;
    }

    return (int)value;
}

int main(int argc, char **argv)
{
    int value;

    if (argc != 2) {
        fprintf(stderr, "Usage: %s <off|restore|0|1|2>\n", argv[0]);
        return EXIT_FAILURE;
    }

    if (strcmp(argv[1], "off") == 0) {
        value = read_brightness();
        if (value < 0 || save_state(value) != 0 || write_brightness(0) != 0)
            return EXIT_FAILURE;
        return EXIT_SUCCESS;
    }

    if (strcmp(argv[1], "restore") == 0) {
        value = load_state();
        if (value < 0 || write_brightness(value) != 0)
            return EXIT_FAILURE;
        return EXIT_SUCCESS;
    }

    if (strcmp(argv[1], "0") == 0)
        value = 0;
    else if (strcmp(argv[1], "1") == 0)
        value = 1;
    else if (strcmp(argv[1], "2") == 0)
        value = 2;
    else {
        fprintf(stderr, "Argument must be off, restore, 0, 1, or 2.\n");
        return EXIT_FAILURE;
    }

    return write_brightness(value) == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
