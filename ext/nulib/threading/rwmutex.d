/**
    Read-Write Mutually Exclusive Locks

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.rwmutex;
import nulib.threading.mutex;
import nulib.threading.atomic;
import numem;

/**
    A mutex which allows multiple multiple readers to pass
    while blocking on write.

    This RWMutex implementation is read-preferring.
*/
class RWMutex : NuObject {
private:
@nogc:
    Atomic!uint readers;
    Mutex readMutex;
    Mutex writeMutex;

public:
    
    class Reader {
    public:
    @nogc:

        /**
            Peforms a reader lock operation.
        */
        void lock() {
            readMutex.lock();
            readers += 1;
            if (readers == 1)
                writeMutex.lock();
            readMutex.unlock();
        }

        /**
            Peforms a reader unlock operation.
        */
        void unlock() {
            readMutex.lock();
            readers -= 1;
            if (readers == 0)
                writeMutex.unlock();
            readMutex.unlock();
        }

    }

    class Writer {
    public:
    @nogc:

        /**
            Peforms a writer lock operation.
        */
        void lock() {
            writeMutex.lock();
        }

        /**
            Peforms a writer unlock operation.
        */
        void unlock() {
            writeMutex.unlock();
        }

    }

    /**
        The reader lock.
    */
    Reader reader;

    /**
        The writer lock.
    */
    Writer writer;

    /// Destructor
    ~this() {
        readers = 0;
        nogc_delete(readMutex);
        nogc_delete(writeMutex);
    }

    /**
        Creates a new read-write mutex.
    */
    this() {
        readers = 0;
        readMutex = nogc_new!Mutex();
        writeMutex = nogc_new!Mutex();
    }
}