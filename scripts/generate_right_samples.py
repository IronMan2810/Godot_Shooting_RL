import pyautogui
import time
import random


def win_with_left():
    for _ in range(45):
        pyautogui.moveTo(-100, 0)
    pyautogui.click(0, 0)


def win_with_right():
    for _ in range(30):
        pyautogui.moveTo(100, 0)
    pyautogui.click(0, 0)


def generate_samples(N):
    for _ in range(N):
        r = random.choice([0, 1])
        if r == 1:
            win_with_left()
        else:
            win_with_right()


if __name__ == "__main__":
    time.sleep(2)
    generate_samples(100)
