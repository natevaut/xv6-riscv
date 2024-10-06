#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

/*
int fork(void);
int pipe(int *);
int read(int, void *, int);
int write(int, const void *, int);
*/

#define READEND(pipe_rw) pipe_rw[0]
#define WRITEEND(pipe_rw) pipe_rw[1]
#define READVAL(pipe_rw, var) read(READEND(pipe_rw), &var, sizeof(var))
#define WRITEVAL(pipe_rw, var) write(WRITEEND(pipe_rw), &var, sizeof(var))
#define DEFAULT 4

int main()
{
    int pipeToChild[2];
    int pipeToParent[2];
    pipe(pipeToChild);
    pipe(pipeToParent);

    int forkPid = fork();
    int curPid = getpid();

    if (forkPid < 0)
    {
        printf("pingpong failed: failed to fork()");
        exit(1);
    }
    else if (forkPid == 0)
    { // in child process
        // close unused pipes
        close(WRITEEND(pipeToChild));
        close(READEND(pipeToParent));

        int value;

        // read val from parent process
        READVAL(pipeToChild, value);

        printf("%d Integer from parent: %d\n", curPid, value);

        // change val and write it back to parent
        value *= 4;
        WRITEVAL(pipeToParent, value);

        close(READEND(pipeToChild));
        close(WRITEEND(pipeToParent));

        exit(0);
    }
    else
    { // parent process
        // close unused pipes
        close(READEND(pipeToChild));
        close(WRITEEND(pipeToParent));

        int value;

        // write val to child
        value = DEFAULT;
        WRITEVAL(pipeToChild, value);

        // wait until child ends
        wait(0);

        // read val from child
        READVAL(pipeToParent, value);

        printf("%d Integer from child: %d\n", curPid, value);

        close(READEND(pipeToParent));
        close(WRITEEND(pipeToChild));

        exit(0);
    }
}
