#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <linux/capability.h>
#include <pwd.h>
#include <sched.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mount.h>
#include <sys/prctl.h>
#include <sys/syscall.h>
#include <unistd.h>

#ifndef APP_BIN
#error "APP_BIN must be set at build time"
#endif

#ifndef APP_USER
#error "APP_USER must be set at build time"
#endif

#define APP_VPN_NETNS "/run/netns/app-vpn"
#define APP_VPN_RESOLV_CONF "/run/app-vpn/resolv.conf"

static void fail(const char *operation)
{
    fprintf(stderr, "app-vpn: %s: %s\n", operation, strerror(errno));
    exit(126);
}

static void drop_capabilities(void)
{
    struct __user_cap_header_struct header = {
        .version = _LINUX_CAPABILITY_VERSION_3,
        .pid = 0,
    };
    struct __user_cap_data_struct data[2] = { 0 };

    if (syscall(SYS_capset, &header, data) != 0) {
        fail("drop capabilities");
    }

    if (prctl(PR_CAP_AMBIENT, PR_CAP_AMBIENT_CLEAR_ALL, 0, 0, 0) != 0) {
        fail("clear ambient capabilities");
    }

    if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) != 0) {
        fail("set no-new-privileges");
    }
}

int main(int argc, char **argv)
{
    if (getuid() == 0) {
        fprintf(stderr, "app-vpn: refusing to launch as root\n");
        return 126;
    }

    struct passwd *user = getpwuid(getuid());
    if (user == NULL || strcmp(user->pw_name, APP_USER) != 0) {
        fprintf(stderr, "app-vpn: refusing to launch for an unexpected user\n");
        return 126;
    }

    int namespace_fd = open(APP_VPN_NETNS, O_RDONLY | O_CLOEXEC);
    if (namespace_fd < 0) {
        fprintf(stderr, "app-vpn: Proton tunnel is unavailable; application was not started\n");
        return 126;
    }

    if (setns(namespace_fd, CLONE_NEWNET) != 0) {
        fail("enter application network namespace");
    }
    close(namespace_fd);

    if (unshare(CLONE_NEWNS) != 0) {
        fail("create private mount namespace");
    }

    if (mount(NULL, "/", NULL, MS_REC | MS_PRIVATE, NULL) != 0) {
        fail("make mount namespace private");
    }

    if (mount(APP_VPN_RESOLV_CONF, "/etc/resolv.conf", NULL, MS_BIND, NULL) != 0) {
        fail("install Proton DNS resolver");
    }

    if (mount(NULL, "/etc/resolv.conf", NULL, MS_BIND | MS_REMOUNT | MS_RDONLY, NULL) != 0) {
        fail("make Proton DNS resolver read-only");
    }

    drop_capabilities();

    char **app_argv = calloc((size_t)argc + 1, sizeof(char *));
    if (app_argv == NULL) {
        fail("allocate application arguments");
    }

    app_argv[0] = (char *)APP_BIN;
    for (int i = 1; i < argc; i++) {
        app_argv[i] = argv[i];
    }

    execv(APP_BIN, app_argv);
    fail("start application");
}
