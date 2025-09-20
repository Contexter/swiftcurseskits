#ifndef CNCURSES_SUPPORT_SHIMS_H
#define CNCURSES_SUPPORT_SHIMS_H

#include <stdbool.h>
#include <stdint.h>
#include <ncursesw/curses.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef void *CNCursesWindowRef;

static inline CNCursesWindowRef cncurses_initscr(void) {
    WINDOW *window = initscr();
    return (CNCursesWindowRef)window;
}

static inline CNCursesWindowRef cncurses_stdscr(void) {
    return (CNCursesWindowRef)stdscr;
}

static inline int32_t cncurses_endwin(void) {
    return (int32_t)endwin();
}

static inline int32_t cncurses_cbreak(void) {
    return (int32_t)cbreak();
}

static inline int32_t cncurses_noecho(void) {
    return (int32_t)noecho();
}

static inline int32_t cncurses_keypad(CNCursesWindowRef window, bool enable) {
    return (int32_t)keypad((WINDOW *)window, enable ? TRUE : FALSE);
}

static inline int32_t cncurses_refresh(void) {
    return (int32_t)refresh();
}

static inline int32_t cncurses_erase(void) {
    return (int32_t)erase();
}

static inline int32_t cncurses_delwin(CNCursesWindowRef window) {
    return (int32_t)delwin((WINDOW *)window);
}

static inline int32_t cncurses_ok(void) {
    return (int32_t)OK;
}

static inline int32_t cncurses_error(void) {
    return (int32_t)ERR;
}

static inline bool cncurses_is_endwin(void) {
    return isendwin() ? true : false;
}

#ifdef __cplusplus
}
#endif

#endif /* CNCURSES_SUPPORT_SHIMS_H */
