/**
    Thread Pools

    Copyright:
        Copyright © 2023-2025, Kitsunebi Games
        Copyright © 2023-2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nulib.threading.threadpool;
import nulib.threading.internal.thread;
import nulib.threading.thread;
import nulib.threading.mutex;
import numem;

/**
    Gets the total number of CPUs in the system.

    Returns:
        The number of CPUs in the system.
*/
alias totalCPUs = nulib.threading.internal.thread.totalCPUs;