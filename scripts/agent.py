import random
import tensorflow as tf
import numpy as np  # numpy
from collections import deque  # data structure to store memory
from constants import MAX_MEMORY, BATCH_SIZE, LR, NUM_ACTIONS, GAMMA, epsilon_random_frames
from model import Linear_QNet
from trainer import QTrainer
import os
import json


class Agent:
    def __init__(self, agent_n):
        self.agent_n = agent_n
        self.epsilon = 1.0 
        self.n_games = 0
        self.state_num = 0
        self.memory = deque(maxlen=MAX_MEMORY)
        self.model = Linear_QNet(
            256, NUM_ACTIONS, agent_n
        )  # input size, hidden size, output size
        self.trainer = QTrainer(self.model, lr=LR, gamma=GAMMA)

    def get_state(self, socket):
        bufferSize = 256
        msgFromServer = socket.recv(bufferSize).decode('utf8')
        f = json.loads(msgFromServer)
        state = [
            f["current_distance"],
            f["left_distance"],
            f["right_distance"],
            f["delta_distance"],
        ]
        return np.array(state, dtype=np.float32), f["reward"], f["done"]

    def remember(self, state, action, reward, next_state, done):
        self.memory.append(
            (state, action, reward, next_state, done)
        )  # popleft if MAX_MEMORY is reached

    def train_long_memory(self):
        mini_sample = random.sample(self.memory, BATCH_SIZE)  # list of tuples
        states, actions, rewards, next_states, dones = list(
            map(lambda x: np.array(x), zip(*mini_sample))
        )
        self.trainer.train_step(states, actions, rewards, next_states, dones)

    def train_short_memory(self, state, action, reward, next_state, done):
        self.trainer.train_step(state, action, reward, next_state, done)

    def get_action(self, state):
        if self.state_num < epsilon_random_frames or self.epsilon > np.random.rand(1)[0]:
            action = np.random.choice(NUM_ACTIONS)
        else:
            state_tensor = tf.convert_to_tensor(state)
            state_tensor = tf.expand_dims(state_tensor, 0)
            action_probs = self.model(state_tensor, training=False)
            action = tf.argmax(action_probs[0]).numpy()
        self.state_num += 1
        return action

    def load_model(self):
        if os.path.exists(f"./info_models/agent{self.agent_n}/model.h5"):
            try:
                self.model.load_weights(f"./info_models/agent{self.agent_n}/model.h5")
                self.trainer.load_model(self.model)
            except:
                print(f"Agent{self.agent_n} Cant load pretrained model")
        else:
            print(f"Agent{self.agent_n} Model Doesn't exist")

