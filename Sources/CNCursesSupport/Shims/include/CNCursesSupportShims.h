#ifndef CNCURSES_SUPPORT_SHIMS_H
#define CNCURSES_SUPPORT_SHIMS_H

#include <stdbool.h>
#include <stdint.h>

#if defined(__APPLE__)
#    if __has_include(<ncurses.h>)
#        include <ncurses.h>
#    elif __has_include(<ncursesw/curses.h>)
#        include <ncursesw/curses.h>
#    else
#        error "Unable to locate Homebrew ncurses headers. Install ncurses with wide-character support (brew install ncurses)."
#    endif
#else
#    if __has_include(<ncursesw/curses.h>)
#        include <ncursesw/curses.h>
#    elif __has_include(<ncurses/curses.h>)
#        include <ncurses/curses.h>
#    elif __has_include(<ncurses.h>)
#        include <ncurses.h>
#    else
#        error "Unable to locate an ncurses header. SwiftCursesKit requires ncurses with wide-character support."
#    endif

#endif

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

static inline int32_t cncurses_nodelay(CNCursesWindowRef window, bool enable) {
    return (int32_t)nodelay((WINDOW *)window, enable ? TRUE : FALSE);
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

static inline CNCursesWindowRef cncurses_newwin(int32_t height, int32_t width, int32_t y, int32_t x) {
    WINDOW *window = newwin(height, width, y, x);
    return (CNCursesWindowRef)window;
}

static inline int32_t cncurses_wclear(CNCursesWindowRef window) {
    return (int32_t)wclear((WINDOW *)window);
}

static inline int32_t cncurses_mvwaddnstr(
    CNCursesWindowRef window, int32_t y, int32_t x, const char *text, int32_t length
) {
    return (int32_t)mvwaddnstr((WINDOW *)window, y, x, text, length);
}

static inline int32_t cncurses_wgetch(CNCursesWindowRef window) {
    return (int32_t)wgetch((WINDOW *)window);
}

static inline int32_t cncurses_wnoutrefresh(CNCursesWindowRef window) {
    return (int32_t)wnoutrefresh((WINDOW *)window);
}

static inline int32_t cncurses_doupdate(void) {
    return (int32_t)doupdate();
}

static inline bool cncurses_has_colors(void) {
    return has_colors() ? true : false;
}

static inline int32_t cncurses_start_color(void) {
    return (int32_t)start_color();
}

static inline int32_t cncurses_use_default_colors(void) {
    return (int32_t)use_default_colors();
}

static inline int32_t cncurses_init_pair(int16_t pair, int16_t foreground, int16_t background) {
    return (int32_t)init_pair(pair, foreground, background);
}

static inline int32_t cncurses_color_pair_count(void) {
    return (int32_t)COLOR_PAIRS;
}

static inline int32_t cncurses_color_count(void) {
    return (int32_t)COLORS;
}

static inline bool cncurses_can_change_color(void) {
    return can_change_color() ? true : false;
}

static inline int16_t cncurses_color_black(void) {
    return (int16_t)COLOR_BLACK;
}

static inline int16_t cncurses_color_red(void) {
    return (int16_t)COLOR_RED;
}

static inline int16_t cncurses_color_green(void) {
    return (int16_t)COLOR_GREEN;
}

static inline int16_t cncurses_color_yellow(void) {
    return (int16_t)COLOR_YELLOW;
}

static inline int16_t cncurses_color_blue(void) {
    return (int16_t)COLOR_BLUE;
}

static inline int16_t cncurses_color_magenta(void) {
    return (int16_t)COLOR_MAGENTA;
}

static inline int16_t cncurses_color_cyan(void) {
    return (int16_t)COLOR_CYAN;
}

static inline int16_t cncurses_color_white(void) {
    return (int16_t)COLOR_WHITE;
}

static inline bool cncurses_has_mouse(void) {
    return has_mouse() ? true : false;
}

static inline unsigned long cncurses_all_mouse_events(void) {
    return (unsigned long)ALL_MOUSE_EVENTS;
}

static inline unsigned long cncurses_report_mouse_position(void) {
    return (unsigned long)REPORT_MOUSE_POSITION;
}

static inline int32_t cncurses_set_mousemask(unsigned long mask) {
    mmask_t previous = mousemask((mmask_t)mask, NULL);
    if (previous == (mmask_t)ERR) {
        return (int32_t)ERR;
    }
    return (int32_t)OK;
}

static inline void cncurses_getmaxyx(CNCursesWindowRef window, int32_t *rows, int32_t *columns) {
    int y = 0;
    int x = 0;
    getmaxyx((WINDOW *)window, y, x);
    if (rows != NULL) {
        *rows = (int32_t)y;
    }
    if (columns != NULL) {
        *columns = (int32_t)x;
    }
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
