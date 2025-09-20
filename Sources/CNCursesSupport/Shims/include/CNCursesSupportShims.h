#ifndef CNCURSES_SUPPORT_SHIMS_H
#define CNCURSES_SUPPORT_SHIMS_H

#include <stdbool.h>
#include <stdint.h>
#include <ncursesw/curses.h>
#include <wchar.h>

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

static inline int32_t cncurses_wget_wch(CNCursesWindowRef window, uint32_t *value) {
    wint_t ch = 0;
    int32_t result = (int32_t)wget_wch((WINDOW *)window, &ch);
    if (value != NULL) {
        *value = (uint32_t)ch;
    }
    return result;
}

static inline bool cncurses_has_mouse(void) {
    return has_mouse() ? true : false;
}

typedef struct {
    int16_t identifier;
    int32_t x;
    int32_t y;
    int32_t z;
    uint64_t state;
} CNCursesMouseEvent;

static inline int32_t cncurses_getmouse(CNCursesMouseEvent *event) {
    MEVENT rawEvent;
    int32_t result = (int32_t)getmouse(&rawEvent);
    if (result == ERR) {
        return result;
    }
    if (event != NULL) {
        event->identifier = rawEvent.id;
        event->x = rawEvent.x;
        event->y = rawEvent.y;
        event->z = rawEvent.z;
        event->state = (uint64_t)rawEvent.bstate;
    }
    return result;
}

static inline uint64_t cncurses_mousemask(uint64_t newmask, uint64_t *oldmask) {
    mmask_t previousMask = 0;
    mmask_t result = mousemask((mmask_t)newmask, oldmask != NULL ? &previousMask : NULL);
    if (oldmask != NULL) {
        *oldmask = (uint64_t)previousMask;
    }
    return (uint64_t)result;
}

static inline uint32_t cncurses_key_code_yes(void) {
    return (uint32_t)KEY_CODE_YES;
}

static inline uint32_t cncurses_key_mouse(void) {
    return (uint32_t)KEY_MOUSE;
}

static inline uint32_t cncurses_key_resize(void) {
    return (uint32_t)KEY_RESIZE;
}

static inline uint32_t cncurses_key_enter(void) {
    return (uint32_t)KEY_ENTER;
}

static inline uint32_t cncurses_key_backspace(void) {
    return (uint32_t)KEY_BACKSPACE;
}

static inline uint32_t cncurses_key_up(void) {
    return (uint32_t)KEY_UP;
}

static inline uint32_t cncurses_key_down(void) {
    return (uint32_t)KEY_DOWN;
}

static inline uint32_t cncurses_key_left(void) {
    return (uint32_t)KEY_LEFT;
}

static inline uint32_t cncurses_key_right(void) {
    return (uint32_t)KEY_RIGHT;
}

static inline uint32_t cncurses_key_home(void) {
    return (uint32_t)KEY_HOME;
}

static inline uint32_t cncurses_key_end(void) {
    return (uint32_t)KEY_END;
}

static inline uint32_t cncurses_key_npage(void) {
    return (uint32_t)KEY_NPAGE;
}

static inline uint32_t cncurses_key_ppage(void) {
    return (uint32_t)KEY_PPAGE;
}

static inline uint32_t cncurses_key_ic(void) {
    return (uint32_t)KEY_IC;
}

static inline uint32_t cncurses_key_dc(void) {
    return (uint32_t)KEY_DC;
}

static inline uint32_t cncurses_key_btab(void) {
    return (uint32_t)KEY_BTAB;
}

static inline uint32_t cncurses_key_f(int32_t index) {
    return (uint32_t)KEY_F(index);
}

static inline uint64_t cncurses_all_mouse_events(void) {
    return (uint64_t)ALL_MOUSE_EVENTS;
}

static inline uint64_t cncurses_report_mouse_position(void) {
    return (uint64_t)REPORT_MOUSE_POSITION;
}

static inline uint64_t cncurses_button1_pressed(void) {
    return (uint64_t)BUTTON1_PRESSED;
}

static inline uint64_t cncurses_button1_released(void) {
    return (uint64_t)BUTTON1_RELEASED;
}

static inline uint64_t cncurses_button1_clicked(void) {
    return (uint64_t)BUTTON1_CLICKED;
}

static inline uint64_t cncurses_button1_double_clicked(void) {
    return (uint64_t)BUTTON1_DOUBLE_CLICKED;
}

static inline uint64_t cncurses_button1_triple_clicked(void) {
    return (uint64_t)BUTTON1_TRIPLE_CLICKED;
}

static inline uint64_t cncurses_button2_pressed(void) {
    return (uint64_t)BUTTON2_PRESSED;
}

static inline uint64_t cncurses_button2_released(void) {
    return (uint64_t)BUTTON2_RELEASED;
}

static inline uint64_t cncurses_button2_clicked(void) {
    return (uint64_t)BUTTON2_CLICKED;
}

static inline uint64_t cncurses_button2_double_clicked(void) {
    return (uint64_t)BUTTON2_DOUBLE_CLICKED;
}

static inline uint64_t cncurses_button2_triple_clicked(void) {
    return (uint64_t)BUTTON2_TRIPLE_CLICKED;
}

static inline uint64_t cncurses_button3_pressed(void) {
    return (uint64_t)BUTTON3_PRESSED;
}

static inline uint64_t cncurses_button3_released(void) {
    return (uint64_t)BUTTON3_RELEASED;
}

static inline uint64_t cncurses_button3_clicked(void) {
    return (uint64_t)BUTTON3_CLICKED;
}

static inline uint64_t cncurses_button3_double_clicked(void) {
    return (uint64_t)BUTTON3_DOUBLE_CLICKED;
}

static inline uint64_t cncurses_button3_triple_clicked(void) {
    return (uint64_t)BUTTON3_TRIPLE_CLICKED;
}

static inline uint64_t cncurses_button4_pressed(void) {
    return (uint64_t)BUTTON4_PRESSED;
}

static inline uint64_t cncurses_button5_pressed(void) {
    return (uint64_t)BUTTON5_PRESSED;
}

#ifdef BUTTON6_PRESSED
static inline uint64_t cncurses_button6_pressed(void) {
    return (uint64_t)BUTTON6_PRESSED;
}
#else
static inline uint64_t cncurses_button6_pressed(void) {
    return 0;
}
#endif

#ifdef BUTTON7_PRESSED
static inline uint64_t cncurses_button7_pressed(void) {
    return (uint64_t)BUTTON7_PRESSED;
}
#else
static inline uint64_t cncurses_button7_pressed(void) {
    return 0;
}
#endif

static inline uint64_t cncurses_button_shift(void) {
    return (uint64_t)BUTTON_SHIFT;
}

static inline uint64_t cncurses_button_ctrl(void) {
    return (uint64_t)BUTTON_CTRL;
}

static inline uint64_t cncurses_button_alt(void) {
    return (uint64_t)BUTTON_ALT;
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

static inline int32_t cncurses_wnoutrefresh(CNCursesWindowRef window) {
    return (int32_t)wnoutrefresh((WINDOW *)window);
}

static inline int32_t cncurses_doupdate(void) {
    return (int32_t)doupdate();
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
