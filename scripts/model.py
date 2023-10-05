import os
import tensorflow as tf

class Linear_QNet(tf.keras.Model):
    def __init__(
        self, hidden_size, output_size, agent_n
    ):  # building the input, hidden and output layer
        super().__init__()
        self.linear1 = tf.keras.layers.Dense(hidden_size, activation="relu")
        self.linear2 = tf.keras.layers.Dense(hidden_size, activation="relu")
        self.linear3 = tf.keras.layers.Dense(output_size, activation="linear")
        self.agent_n = agent_n

    def call(self, x):  # this is a feed-forward neural net
        x = self.linear1(x)
        x = self.linear2(x)
        out = self.linear3(x)
        return out

    def save(self, file_name="model.h5"):  # saving the model
        model_folder_path = f"./models/agent{self.agent_n}"
        if not os.path.exists(model_folder_path):
            os.makedirs(model_folder_path)
        file_name = os.path.join(model_folder_path, file_name)
        self.save_weights(file_name)
