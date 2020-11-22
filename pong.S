# Pongloader - pong made to fit in 512 bytes.
# It's designed to be bootable by IBM-compatible PCs.
# The code is optimized for space taken by the code
# and not performance. Don't expect great code in here.

# Reserved registers:
# BP = Ball Y
# SI = Ball direction Y
# DI = Ball X

# Graphics mode constants (13h - 320x200).
SCREEN_WIDTH = 320
SCREEN_HEIGHT = 200

# Pong constants.
PONG_HEIGHT = 20
PONG_WIDTH = 4 # Don't change this one, it should always stay at 4.
PONG_OFFSET = 10
PONG_MOVEMENT_SPEED = 8
PONG_COMPUTER_SPEED = 2 # Less is faster.
PONG_FORCE_FIELD = 4 # Collision tolerance, makes game easier.

# Computed values (based on settings above).
TWICE_SCREEN_WIDTH = SCREEN_WIDTH * 2
HALF_SCREEN_WIDTH = SCREEN_WIDTH / 2
SCREEN_WIDTH_TIMES_MOVEMENT_SPEED = PONG_MOVEMENT_SPEED * SCREEN_WIDTH

PONG_HEIGHT_HALF = PONG_HEIGHT / 2
PONG_DEFAULT_Y = SCREEN_HEIGHT / 2 - PONG_HEIGHT_HALF
PONG_OFFSET_RIGHT = SCREEN_WIDTH - PONG_OFFSET - PONG_WIDTH

PONG_COLLISION_MIN_Y = -1 * PONG_FORCE_FIELD
PONG_COLLISION_MAX_Y = PONG_HEIGHT + PONG_FORCE_FIELD

PONG_MAX_Y = SCREEN_HEIGHT - PONG_HEIGHT

PONG_BALL_MIN_X = PONG_OFFSET + PONG_WIDTH
PONG_BALL_MAX_X = PONG_OFFSET_RIGHT - PONG_WIDTH

TWICE_PONG_MOVEMENT_SPEED = PONG_MOVEMENT_SPEED * 2
DRAW_PLAYER_MEMORY_OFFSET = SCREEN_WIDTH_TIMES_MOVEMENT_SPEED + SCREEN_WIDTH

# Memory.
VGA_START = 0xA000
MEMORY_OFFSET = 0xFFD0 # I'm storing data in the VGA memory, unsafe, but seems to work.
PONG_MEMORY_LEFT_Y = MEMORY_OFFSET
PONG_MEMORY_RIGHT_Y = MEMORY_OFFSET + 2
PONG_MEMORY_BALL_DIRECTION_X = MEMORY_OFFSET + 8
PONG_MEMORY_GAME_END = MEMORY_OFFSET + 12
PONG_MEMORY_RIGHT_TEMP = MEMORY_OFFSET + 14

# Keyboard scancodes.
KEY_UP = 0x48
KEY_DOWN = 0x50

.code16
.global init

init:
    # Set graphics mode to 13h (320x200, 256bit color).
    mov $0x13, %ax
    int $0x10

    # I will be storing data in the VGA memory.
    # It's theoretically not safe, but seems to work.
    mov $VGA_START, %ax
    mov %ax, %ds

    # Initialize variables.
    xor %si, %si

    mov $1, (PONG_MEMORY_BALL_DIRECTION_X)

    mov $HALF_SCREEN_WIDTH, %di # DI = Ball X

    mov $PONG_DEFAULT_Y, %ax
    mov %ax, (PONG_MEMORY_LEFT_Y)
    mov %ax, (PONG_MEMORY_RIGHT_Y)

    add $0x8, %ax
    mov %ax, %bp # BP = Ball Y

    jmp keyboard

main:
    # Delay frame by 32ms. (30 FPS)
    mov $0x8600, %ax
    xor %cx, %cx
    mov $0x2000, %dx
    int $0x15

keyboard:
    # Check if a key is pressed.
    mov $0x01, %ah
    int $0x16

    mov (PONG_MEMORY_LEFT_Y), %cx

    # If a key is pressed get it.
    jz drawLeft
    xor %ah, %ah
    int $0x16

    cmp $KEY_UP, %ah
    je moveUp

    cmp $KEY_DOWN, %ah
    je moveDown

    jmp drawLeft

moveUp:
    sub $TWICE_PONG_MOVEMENT_SPEED, %cx
    
moveDown:
    add $PONG_MOVEMENT_SPEED, %cx

afterLeftMove:
    call sanityCheckBottom

drawLeft:
    # Persist position.
    mov %cx, (PONG_MEMORY_LEFT_Y)
    mov $PONG_OFFSET, %bx

    call drawPlayer

drawRight:
    mov (PONG_MEMORY_RIGHT_Y), %cx
    mov $PONG_OFFSET_RIGHT, %bx

    call drawPlayer

drawBall:
    mov %bp, %ax # BP = Ball Y
    mov $SCREEN_WIDTH, %cx
    mul %cx
    add %di, %ax # DI = Ball X

    mov %ax, %bx

    sub $TWICE_SCREEN_WIDTH, %bx
    call clear
    movl $0x00000000, (%bx)
    call clear
    movl $0x000f0f00, (%bx)
    call clear
    movl $0x0f0f0f0f, (%bx)
    call clear
    movl $0x0f0f0f0f, (%bx)
    call clear
    movl $0x000f0f00, (%bx)
    call clear
    movl $0x00000000, (%bx)

ballPhysicsRight:
    # Check if the right side (or right player) was hit.
    mov %di, %bx # DI = Ball X
    
    cmp $PONG_BALL_MAX_X, %bx
    jl ballPhysicsLeft

    # We're behind the right player.
    # Let's check whether we should trigger defeat.
    mov %bp, %ax # BP = Ball Y
    sub (PONG_MEMORY_RIGHT_Y), %ax

    call playerPhysics

    mov $-1, (PONG_MEMORY_BALL_DIRECTION_X)
    jmp ballPhysicsTop

ballPhysicsLeft:
    # Check if the left side (or left player) was hit.
    cmp $PONG_BALL_MIN_X, %bx
    jg ballPhysicsTop

    # We're behind the left player.
    # Let's check whether we should trigger defeat.
    mov %bp, %ax # BP = Ball Y
    sub (PONG_MEMORY_LEFT_Y), %ax

    call playerPhysics

    mov $1, (PONG_MEMORY_BALL_DIRECTION_X)

ballPhysicsTop:
    # Bounce (top).
    mov %bp, %ax # BP = Ball Y
    test %ax, %ax
    
    jg ballPhysicsBottom

    mov $1, %si # SI = Ball direction Y

ballPhysicsBottom:
    # Bounce (bottom).
    add $4, %ax
    cmp $SCREEN_HEIGHT, %ax
    
    jl moveBall

    mov $-1, %si # SI = Ball direction Y

moveBall:
    # Update ball's position.
    add (PONG_MEMORY_BALL_DIRECTION_X), %di # DI = Ball X
    
    add %si, %bp # SI = Ball direction Y, BP = Ball Y

moveRight:
    # Update right player's position.
    # Follows the ball's Y (with a delay that allows the human player to win).
    mov (PONG_MEMORY_RIGHT_TEMP), %bx
    inc %bx
    cmp $PONG_COMPUTER_SPEED, %bx
    mov %bx, (PONG_MEMORY_RIGHT_TEMP)
    jl main
    
    xor %bx, %bx
    mov %bx, (PONG_MEMORY_RIGHT_TEMP)

    mov (PONG_MEMORY_RIGHT_Y), %cx
    cmp %bp, %cx # BP = Ball Y
    je main
    jl rightMoveDown

    # move up
    dec %cx
    jmp afterRightMove

rightMoveDown:
    inc %cx

afterRightMove:
    # Force the right player to not escape screen bounds (bottom).
    call sanityCheckBottom
    mov %cx, (PONG_MEMORY_RIGHT_Y)
    jmp main

# Procedures.
clear:
    add $SCREEN_WIDTH, %bx
    movl $0x00000000, -1(%bx)
    movl $0x00000000, 1(%bx)
    ret

drawPlayer:
    mov $SCREEN_WIDTH, %ax
    mul %cx
    add %ax, %bx
    sub $DRAW_PLAYER_MEMORY_OFFSET, %bx

    xor %cx, %cx
    clearPlayerTopLoop:
        inc %cx

        movl $0x00000000, (%bx)
        add $SCREEN_WIDTH, %bx

        cmp $PONG_MOVEMENT_SPEED, %cx
        jle clearPlayerTopLoop

    xor %cx, %cx
    drawPlayerLoop:
        inc %cx

        movl $0x0f0f0f0f, (%bx)
        add $SCREEN_WIDTH, %bx

        cmp $PONG_HEIGHT, %cx
        jle drawPlayerLoop

    xor %cx, %cx
    clearPlayerBottomLoop:
        inc %cx

        movl $0x0000000, (%bx)
        add $SCREEN_WIDTH, %bx

        cmp $PONG_MOVEMENT_SPEED, %cx
        jle clearPlayerBottomLoop

    ret

playerPhysics:
    # End the game if sides are hit.
    cmp $PONG_COLLISION_MIN_Y, %ax
    jl init
    cmp $PONG_FORCE_FIELD, %ax
    jg playerPhysicsSecondCheck

    # Change ball's vertical velocity if the player was hit from the bottom.
    mov $-1, %si # SI = Ball direction Y
    
playerPhysicsSecondCheck:
    cmp $PONG_COLLISION_MAX_Y, %ax
    jg init
    cmp $PONG_HEIGHT_HALF, %ax
    jl playerPhysicsEnd

    # Change ball's vertical velocity if the player was hit from the top.
    mov $1, %si # SI = Ball direction Y

playerPhysicsEnd:
    ret

sanityCheckBottom:
    # Force the player to not escape screen bounds (bottom).
    cmp $PONG_MAX_Y, %cx
    jl sanityCheckTop
    mov $PONG_MAX_Y, %cx

sanityCheckTop:
    # Force the player to not escape screen bounds (top).
    test %cx, %cx
    jg sanityCheckEnd
    xor %cx, %cx

sanityCheckEnd:
    ret

.fill 510-(.-init), 1, 0
.word 0xaa55
