#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

#define NFORK 10
#define IO 5

int main()
{
    int n, pid;
    int org, new;
    int wtime, rtime, stime;
    int twtime = 0, trtime = 0, tstime = 0;
    for (n = 0; n < NFORK; n++)
    {
        pid = fork();
        if (pid < 0)
            break;
        if (pid == 0)
        {
            if (n < IO)
            {
                sleep(200); // IO bound processes
            }
            else
            {
                for (volatile int i = 0; i < 1000000000; i++)
                {
                    // CPU bound process
                }
            }
            exit(0);
        }
        else
        {
            if (n < IO)
            {
                org = setnice(pid, 18); // Set lower priority for IO bound processes
                new = getnice(pid);
                printf("Process %d original nice is %d, now changed to %d\n", pid, org, new);
            }
        }
    }
    for (; n > 0; n--)
    {
        if (wait2(0, &rtime, &wtime, &stime) >= 0)
        {
            trtime += rtime;
            twtime += wtime;
            tstime += stime;
        }
    }
    printf("Average run-time = %d,  wait time = %d, sleep time = %d\n", trtime / NFORK, twtime / NFORK, tstime / NFORK);
    exit(0);
}
