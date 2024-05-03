//-----------------------------------------------------------------------------
// MIT License
// Copyright (c) 2024 Brian T. Park
//
// Prototype of the LEFT and RIGHT editing cursor using the C language so that I
// can make some sense of the required algorithm, before translating it to Z80
// assembly language.
//
// Some characters in the input_buf[] are transformed into multiple characters
// in the render_buf[], before printed on the LCD screen.
//-----------------------------------------------------------------------------

#include <stdint.h> // uint8_t
#include <stdbool.h> // bool
#include <stdio.h> // printf()
#include <ctype.h> // isupper()
#include <stdlib.h> // exit()
#include <string.h> // strcmp()

#define INPUT_BUF_SIZE 41
#define WINDOW_SIZE_DEFAULT 5

// Characters entered by the user. (Persistent)
static char input_buf[INPUT_BUF_SIZE + 1]; // +1 trailing cursor, +1 NUL
static uint8_t input_buf_len;

// Characters rendered on the screen. (Temporary)
static char render_buf[INPUT_BUF_SIZE*2 + 1 + 1]; // +1 trailing cursor, +1 NUL
static uint8_t render_buf_len;
static uint8_t index_map[INPUT_BUF_SIZE + 1];

// Window over renderBuf to be rendered on the screen. (Persistent)
static uint8_t window_size = WINDOW_SIZE_DEFAULT;
static uint8_t window_start;
static uint8_t window_end; // window=[start,end)

// The position of the cursor using input_buf[] coordinates. (Persistent)
static uint8_t cursor_input_pos;

// The position of the cursor using render_buf[] coordinates. (Temporary)
static uint8_t cursor_render_pos;

// Location of the blinking cursor on the screen. (Temporary)
static uint8_t cursor_screen_pos;

//-----------------------------------------------------------------------------

static void print_debugging()
{
  printf("DEBUG: cursor_input_pos=%d; cursor_screen_pos=%d\n",
      cursor_input_pos,
      cursor_screen_pos);
  printf("DEBUG: window_start=%d; window_end=%d\n",
      window_start,
      window_end);
}

/**
 * Convert input_buf[] into render_buf[], updating index_map[] in the process.
 * Convert all capital letters A-Z into 2 of those capital letters. For example,
 * 'A' converts to 'AA'.
 */
static void render_input()
{
  uint8_t r = 0;
  uint8_t i = 0;
  for (; i < input_buf_len; i++, r++) {
    char c = input_buf[i];
    render_buf[r] = c;
    index_map[i] = r;
    if (isupper(c)) {
      r++;
      render_buf[r] = c;
    }
  }
  // save the length of the render_buf.
  render_buf_len = r;
  // but add a trailing slot for the trailing cursor
  render_buf[r] = ' ';
  index_map[i] = r;
}

static void move_cursor_left()
{
  if (cursor_input_pos != 0) {
    cursor_input_pos--;
  }
}

static void move_cursor_start()
{
  cursor_input_pos = 0;
}

static void move_cursor_right()
{
  if (cursor_input_pos < input_buf_len) {
    cursor_input_pos++; // input_buf_len is allowed
  }
}

static void move_cursor_end()
{
  cursor_input_pos = input_buf_len;
}

static void delete_left_char()
{
  if (cursor_input_pos == 0) return;
  for (uint8_t i = cursor_input_pos; i < input_buf_len; i++) {
    input_buf[i-1] = input_buf[i];
  }
  input_buf_len--;
  cursor_input_pos--;
}

static void insert_char(char c)
{
  for (uint8_t i = input_buf_len; i > cursor_input_pos; i--) {
    input_buf[i] = input_buf[i-1];
  }
  input_buf[cursor_input_pos] = c;
  input_buf_len++;
  cursor_input_pos++;
}

static void update_window()
{
  cursor_render_pos = index_map[cursor_input_pos];
  if (cursor_render_pos <= window_start) {
    if (cursor_render_pos == 0 ) {
      window_start = 0;
    } else {
      window_start = cursor_render_pos - 1;
    }
    window_end = window_start + window_size;
    // TODO: check for overflow?
  } else if (window_end - 1 <= cursor_render_pos) {
    if (cursor_render_pos == render_buf_len) {
      window_end = cursor_render_pos + 1;
    } else {
      window_end = cursor_render_pos + 2;
    }
    window_start = window_end - window_size;
    // TODO: check for underflow?
  } else {
    // do nothing
  }

  // Calc the location of the cursor in screen coordinates.
  cursor_screen_pos = cursor_render_pos - window_start;

  print_debugging();
}

static void print_render_buf()
{
  for (uint8_t i = 0; i < render_buf_len; i++) {
    putchar(render_buf[i]);
  }
  putchar('\n');
}

static void print_render_window()
{
  uint8_t screen_pos = 0;
  for (uint8_t i = window_start; i < window_end; i++) {
    if (cursor_render_pos == i) {
      putchar('_');
    } else {
      if (i < render_buf_len) {
        if (screen_pos == 0 && i != 0) {
          putchar('.');
        } else if (screen_pos == window_size - 1 && i != render_buf_len - 1) {
          putchar('.');
        } else {
          putchar(render_buf[i]);
        }
      } else {
        putchar('$');
      }
    }
    screen_pos++;
  }
  putchar('\n');
}

/**
 * REPL loop. Use vi/vim cursor movement keys (h, l, 0, $). Support deletion of
 * previous character using 'X' (like vi/vim). Support insertion of character at
 * cursor using 'i{char}', where {char} is the character to be inserted.
 *
 * An ENTER character must be entered to send the imnput commands to the
 * program.
 */
static void read_and_print()
{
  while (true) {
    // getchar() is a buffered call, so the user must hit ENTER before the input
    // characters are retrieved by this program. That's a terrible UI, but for
    // the purposes of prototyping and testing, it's more than good enough.
    char c = getchar();

    if (c == 'h') {
      move_cursor_left();
      update_window();
    } else if (c == '0') {
      move_cursor_start();
      update_window();
    } else if (c == 'l') {
      move_cursor_right();
      update_window();
    } else if (c == '$') {
      move_cursor_end();
      update_window();
    } else if (c == 'X') {
      delete_left_char();
      render_input();
      update_window();
    } else if (c == 'i') {
      // Insert the character right after the 'i' command. If there is
      // no {char} after the 'i', do nothing.
      char d = getchar();
      if (d == '\n') {
        ungetc(d, stdin);
        continue;
      }
      insert_char(d);
      render_input();
      update_window();
    } else if (c == '\n') {
      print_render_buf();
      print_render_window();
    } else {
      // do nothing
    }
  }
}

//-----------------------------------------------------------------------------

/** Print usage and exit with status code. (0 means success). */
static void usage_and_exit(int status) {
  fprintf(stderr,
    "Usage: cursor.out string window_size\n"
  );
  exit(status);
}

int main(int argc, const char * const * argv)
{
  // validate and parse command line arguments
  if (argc < 3) {
    usage_and_exit(1);
  }
  const char *string = argv[1];
  const char *window_size_str = argv[2];
  window_size = atoi(window_size_str);

  // copy string on command line to input_buf
  strncpy(input_buf, string, INPUT_BUF_SIZE);
  input_buf[INPUT_BUF_SIZE] = '\0';
  input_buf_len = strlen(input_buf);
  cursor_input_pos = input_buf_len;

  // set screen window
  window_start = 0;
  window_end = window_start + window_size;

  // calculate initial cursor and screen window
  render_input();
  update_window();
  print_render_buf();
  print_render_window();

  read_and_print();
}
