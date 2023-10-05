from utils import (
    PlotAgents,
    clear_existing_model,
    play_step,
)
from constants import BATCH_SIZE
from multiprocessing import Process, shared_memory, Value
import shutil
import numpy as np
import glob
from collections import deque
from agent import Agent
from sys import argv
import socket
import time

epsilon_min = 0.1  # Minimum epsilon greedy parameter
epsilon_max = 1.0  # Maximum epsilon greedy parameter
epsilon_interval = (
    epsilon_max - epsilon_min
)  # Rate at which to reduce chance of random action being taken
# Number of frames for exploration
epsilon_greedy_frames = 1_000_000.0
# Train the model after 4 actions
update_after_actions = 4
# How often to update the target network
update_target_network = 10_000


def train(
    agent_n,
    agents_reward,
    complete,
    plot_now,
    load_agent_model,
    clear_model=True,
):
    if clear_model:
        clear_existing_model()
    serverAddressPort = ("127.0.0.1", 4240 + agent_n)
    TCPClientSocket = socket.socket(family=socket.AF_INET, type=socket.SOCK_STREAM)
    TCPClientSocket.connect(serverAddressPort)
    agent = Agent(agent_n)
    epoch_reward = 0
    epoch_reward_list = deque(maxlen=100)
    starting = str.encode("starting")
    TCPClientSocket.sendall(starting)
    state, _, _ = agent.get_state(TCPClientSocket)
    while True:
        if load_agent_model[agent_n - 1]:
            agent.load_model()
            load_agent_model[agent_n - 1] = False
        final_move = agent.get_action(state)
        play_step(final_move, TCPClientSocket)
        state_new, reward, done = agent.get_state(TCPClientSocket)
        epoch_reward += reward
        agent.remember(state, final_move, reward, state_new, done)
        agent.epsilon -= epsilon_interval / epsilon_greedy_frames
        agent.epsilon = max(agent.epsilon, epsilon_min)
        state = state_new
        if (
            agent.state_num % update_after_actions == 0
            and len(agent.memory) > BATCH_SIZE
        ):
            agent.train_long_memory()
        if agent.state_num % update_target_network == 0:
            # update the the target network with new weights
            agent.trainer.update_model_target()
            agent.model.save()
            # Log details
            with open("./info_models/info.txt", "w") as f:
                f.write(
                    f"epsilon: {agent.epsilon}\nepoch: {agent.n_games}\nstate_num: {agent.state_num}"
                )
        if done:
            agent.n_games += 1
            epoch_reward_list.append(epoch_reward)
            agents_reward[agent_n - 1] = epoch_reward
            complete[agent_n - 1] = True
            if choose_best_gen(agents_reward, complete, plot_now):
                for i in range(len(complete)):
                    complete[i] = False
                    # load_agent_model[i] = True
            epoch_reward = 0
            time.sleep(1)


def choose_best_gen(agents_reward, complete, plot_now):
    if all(c == True for c in complete):
        agent_n = np.argmax(agents_reward) + 1
        for model_path in glob.glob("./info_models/*/model.h5"):
            if not f"agent{agent_n}/" in model_path:
                shutil.copy(f"./info_models/agent{agent_n}/model.h5", model_path)
        plot_now.value = True
        return True
    return False


def start_training(agents_num, enable_plot=False, clear_model=True):
    agents_n = list(range(1, agents_num + 1))
    plotagents = PlotAgents(agents_num)
    plot_now = Value("b", False)
    agents_reward = shared_memory.ShareableList([0] * len(agents_n))
    complete = shared_memory.ShareableList([False] * len(agents_n))
    load_agent_model = shared_memory.ShareableList([True] * len(agents_n))
    for agent_n in agents_n:
        p = Process(
            target=train,
            args=(
                agent_n,
                agents_reward,
                complete,
                plot_now,
                load_agent_model,
                clear_model,
            ),
        )
        p.start()
    while True:
        if enable_plot and plot_now.value:
            for i in range(len(agents_reward)):
                plotagents.update_agent(i + 1, agents_reward[i])
            plotagents.plot()
            plot_now.value = False
    # complete.shm.close()
    # complete.shm.unlink()
    # agents_reward.shm.close()
    # agents_reward.shm.unlink()


if __name__ == "__main__":
    agents_num = int(argv[-1])
    enable_plot = True
    clear_model = False
    start_training(agents_num, enable_plot, clear_model)
