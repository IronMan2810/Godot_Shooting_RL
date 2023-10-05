from multiprocessing import shared_memory, Process



def test(shared_var):
    print(shared_var)

shared_var = shared_memory.SharedMemory("plot_now", True, 1)
r = shared_memory.SharedMemory("plot_now")
print(r.__eq__(1))
p1 = Process(target=test, args=(shared_var,))
p1.start()
p1.join()

shared_var.close()
shared_var.unlink()
