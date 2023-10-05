import tensorflow as tf
from constants import NUM_ACTIONS

class QTrainer:
    def __init__(self, model, lr, gamma): #initializing 
        self.model = None
        self.model_target = None
        self.load_model(model)
        self.lr = lr
        self.gamma = gamma
        self.optimizer = tf.keras.optimizers.Adam(learning_rate=lr, clipnorm=1.0) #optimizer
        self.criterion = tf.keras.losses.Huber() #loss function
        self.lr_count = 0

    def train_step(self, state_sample, action_sample, rewards_sample, state_next_sample, done_sample): #trainer
        future_rewards = self.model_target.predict(state_next_sample, verbose=False) #using the Q=model predict equation above
        updated_q_values = rewards_sample + self.gamma * tf.reduce_max(
                future_rewards, axis=1
            )
        updated_q_values = updated_q_values * (1 - done_sample) - done_sample
        masks = tf.one_hot(action_sample, NUM_ACTIONS)
        with tf.GradientTape() as tape:
            q_values = self.model(state_sample)
            q_action = tf.reduce_sum(tf.multiply(q_values, masks), axis=1)
            loss = self.criterion(updated_q_values, q_action)
        grads = tape.gradient(loss, self.model.trainable_variables)
        self.optimizer.apply_gradients(zip(grads, self.model.trainable_variables))

    def update_model_target(self):
        self.model_target.set_weights(self.model.get_weights())

    def load_model(self, model):
        self.model = model
        self.model_target = model
