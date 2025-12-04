// Control points
typedef enum logic [1:0] {
  INC = 2'b10,
  CLR = 2'b01,
  NO  = 2'b00
} count_t;

typedef enum logic [1:0] {
  SHIFT = 2'b10,
  RST   = 2'b01,
  NONE  = 2'b00
} shift_t;

typedef struct packed {
  count_t clk_ctrl;
  count_t sample_ctrl;
  count_t bit_ctrl;
  shift_t data_ctrl;
} controlPoints_t;