/*    This file is distributed with 42,                               */
/*    the (mostly harmless) spacecraft dynamics simulation            */
/*    created by Eric Stoneking of NASA Goddard Space Flight Center   */

/*    Copyright 2010 United States Government                         */
/*    as represented by the Administrator                             */
/*    of the National Aeronautics and Space Administration.           */

/*    No copyright is claimed in the United States                    */
/*    under Title 17, U.S. Code.                                      */

/*    All Other Rights Reserved.                                      */


#include "42.h"
#include <time.h>
#include <unistd.h>
#include <pthread.h>
#include <signal.h>
#include <arpa/inet.h>
#include <errno.h>

#ifdef _ENABLE_GMSEC_
   #include "gmseckit.h"
   GMSEC_Config cfg;
   GMSEC_ConnectionMgr ConnMgr;
   GMSEC_Status status;
   void WriteToGmsec(GMSEC_ConnectionMgr ConnMgr,GMSEC_Status status);
   void ReadFromGmsec(GMSEC_ConnectionMgr ConnMgr,GMSEC_Status status);
#endif

/* #ifdef __cplusplus
** namespace _42 {
** using namespace Kit;
** #endif
*/

void WriteToFile(FILE *StateFile, char **Prefix, long Nprefix, long EchoEnabled);
void WriteToSocket(SOCKET Socket,  char **Prefix, long Nprefix, long EchoEnabled);
void ReadFromFile(FILE *StateFile, long EchoEnabled);
void ReadFromSocket(SOCKET Socket, long EchoEnabled);

/* Multiplier for IPC array to accommodate multiple/reconnecting clients */
#define IPC_SLOT_MULTIPLIER 10

/* Mutex for protecting the IPC array from concurrent access */
static pthread_mutex_t IpcMutex = PTHREAD_MUTEX_INITIALIZER;

/* Total number of IPC slots allocated (Nipc * IPC_SLOT_MULTIPLIER) */
static long NipcSlots = 0;

/* Structure to hold arguments for the server listener thread */
struct ServerThreadArgs {
   int Port;
   long AllowBlocking;
   long Mode;
   long EchoEnabled;
   char **Prefix;
   long Nprefix;
   long SocketRole;
};

/*********************************************************************/
/* Thread function: listens on a port and accepts connections in a    */
/* loop, adding each new client to the global IPC array.             */
/*********************************************************************/
static void* ServerListenerThread(void* arg)
{
   struct ServerThreadArgs *args = (struct ServerThreadArgs *)arg;
   SOCKET init_sockfd, client_sockfd;
   struct sockaddr_in Server, Client;
   socklen_t clilen;
   int opt = 1;
   int DisableNagle = 1;
   struct IpcType *I;
   long Iipc;

   init_sockfd = socket(AF_INET, SOCK_STREAM, 0);
   if (init_sockfd < 0) {
      printf("Error opening server socket on port %d.\n", args->Port);
      free(args);
      return NULL;
   }

   /* Allow the socket to be reused immediately after close */
   if (setsockopt(init_sockfd, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt)) == -1) {
      printf("Error setting SO_REUSEADDR on port %d.\n", args->Port);
      close(init_sockfd);
      free(args);
      return NULL;
   }

   memset((char *)&Server, 0, sizeof(Server));
   Server.sin_family = AF_INET;
   Server.sin_addr.s_addr = INADDR_ANY;
   Server.sin_port = htons(args->Port);

   if (bind(init_sockfd, (struct sockaddr *)&Server, sizeof(Server)) < 0) {
      printf("Error binding server socket on port %d.\n", args->Port);
      close(init_sockfd);
      free(args);
      return NULL;
   }

   printf("Server is listening on port %d\n", args->Port);
   listen(init_sockfd, 5);
   clilen = sizeof(Client);

   /* Accept connections in a loop forever */
   while (1) {
      client_sockfd = accept(init_sockfd, (struct sockaddr *)&Client, &clilen);
      if (client_sockfd < 0) {
         printf("Error on accept for port %d, retrying...\n", args->Port);
         continue;
      }

      printf("New connection on port %d, socket fd %d, from %s:%d\n",
             args->Port, (int)client_sockfd,
             inet_ntoa(Client.sin_addr), ntohs(Client.sin_port));

      /* Set non-blocking if configured */
      if (!args->AllowBlocking) {
         int flags = fcntl(client_sockfd, F_GETFL, 0);
         fcntl(client_sockfd, F_SETFL, flags | O_NONBLOCK);
      }

      /* Disable Nagle for low-latency messaging */
      setsockopt(client_sockfd, IPPROTO_TCP, TCP_NODELAY,
                 &DisableNagle, sizeof(DisableNagle));

      /* Add the new connection to an available IPC slot */
      pthread_mutex_lock(&IpcMutex);
      for (Iipc = 0; Iipc < NipcSlots; Iipc++) {
         I = &IPC[Iipc];
         if (I->Socket == 0 && I->Init == 0) {
            I->Socket = client_sockfd;
            I->Mode = args->Mode;
            I->SocketRole = args->SocketRole;
            I->AllowBlocking = args->AllowBlocking;
            I->EchoEnabled = args->EchoEnabled;
            I->Prefix = args->Prefix;
            I->Nprefix = args->Nprefix;
            I->Init = 1;
            I->Enabled = 1;
            printf("Assigned connection on port %d to IPC slot %ld\n",
                   args->Port, Iipc);
            break;
         }
      }
      if (Iipc >= NipcSlots) {
         printf("No available IPC slot for connection on port %d. Closing.\n",
                args->Port);
         close(client_sockfd);
      }
      pthread_mutex_unlock(&IpcMutex);
   }

   /* Never reached, but for completeness */
   close(init_sockfd);
   free(args);
   return NULL;
}

/*********************************************************************/
void InitInterProcessComm(void)
{
      FILE *infile;
      char junk[120],newline,response[120];
      struct IpcType *I;
      long Iipc,Ipx;
      char FileName[80],Prefix[80];

      /* Ignore SIGPIPE so writes to disconnected sockets return errors */
      /* instead of crashing the process                                */
      signal(SIGPIPE, SIG_IGN);

      infile = FileOpen(InOutPath,"Inp_IPC.txt","rt");
      fscanf(infile,"%[^\n] %[\n]",junk,&newline);
      fscanf(infile,"%ld %[^\n] %[\n]",&Nipc,junk,&newline);

      /* Allocate extra slots to accommodate reconnecting clients */
      NipcSlots = Nipc * IPC_SLOT_MULTIPLIER;
      IPC = (struct IpcType *) calloc(NipcSlots, sizeof(struct IpcType));

      for(Iipc=0;Iipc<Nipc;Iipc++) {
         I = &IPC[Iipc];
         fscanf(infile,"%[^\n] %[\n]",junk,&newline);
         fscanf(infile,"%s %[^\n] %[\n]",response,junk,&newline);
         I->Mode = DecodeString(response);
         fscanf(infile,"\"%[^\"]\" %[^\n] %[\n]",FileName,junk,&newline);
         fscanf(infile,"%s %[^\n] %[\n]",response,junk,&newline);
         I->SocketRole = DecodeString(response);
         fscanf(infile,"%s %ld %[^\n] %[\n]",I->HostName,&I->Port,junk,&newline);
         fscanf(infile,"%s %[^\n] %[\n]",response,junk,&newline);
         I->AllowBlocking = DecodeString(response);
         fscanf(infile,"%s %[^\n] %[\n]",response,junk,&newline);
         I->EchoEnabled = DecodeString(response);
         fscanf(infile,"%ld %[^\n] %[\n]",&I->Nprefix,junk,&newline);
         I->Prefix = (char **) calloc(I->Nprefix,sizeof(char *));
         for(Ipx=0;Ipx<I->Nprefix;Ipx++) {
            fscanf(infile,"\"%[^\"]\" %[^\n] %[\n]",Prefix,junk,&newline);
            I->Prefix[Ipx] = (char *) calloc(strlen(Prefix)+1,sizeof(char));
            strcpy(I->Prefix[Ipx],Prefix);
         }

         I->Init = 1;
         I->Enabled = 1;

         if (I->Mode == IPC_TX || I->Mode == IPC_RX || I->Mode == IPC_TXRX) {
            if (I->SocketRole == IPC_SERVER) {
               /* Launch a dedicated listener thread for this port */
               pthread_t tid;
               struct ServerThreadArgs *args =
                  (struct ServerThreadArgs *)malloc(sizeof(struct ServerThreadArgs));
               args->Port = I->Port;
               args->AllowBlocking = I->AllowBlocking;
               args->Mode = I->Mode;
               args->EchoEnabled = I->EchoEnabled;
               args->Prefix = I->Prefix;
               args->Nprefix = I->Nprefix;
               args->SocketRole = I->SocketRole;

               /* Mark this config slot as placeholder (no socket yet) */
               I->Socket = 0;
               I->Init = 0;
               I->Enabled = 0;

               if (pthread_create(&tid, NULL, ServerListenerThread, args) != 0) {
                  printf("Error creating listener thread for port %ld\n", I->Port);
                  free(args);
               }
               else {
                  pthread_detach(tid);
               }
            }
            else if (I->SocketRole == IPC_CLIENT) {
               I->Socket = InitSocketClient(I->HostName,I->Port,I->AllowBlocking);
            }
            #ifdef _ENABLE_GMSEC_
            else if (I->SocketRole == IPC_GMSEC_CLIENT) {
               status = statusCreate();
               cfg = configCreate();
               ConnMgr = ConnectToMBServer(I->HostName,I->Port,status,cfg);
               if (I->Mode == IPC_TX)
                  connectionManagerSubscribe(ConnMgr,"GMSEC.42.RX.>",status);
               else if (I->Mode == IPC_RX)
                  connectionManagerSubscribe(ConnMgr,"GMSEC.42.TX.>",status);
               else
                  connectionManagerSubscribe(ConnMgr,"GMSEC.42.TXRX.>",status);
               CheckGmsecStatus(status);
            }
            #endif
            else {
               printf("Oops.  Unknown SocketRole %ld for IPC[%ld] in InitInterProcessComm.  Bailing out.\n",I->SocketRole,Iipc);
               exit(1);
            }
         }
         else if (I->Mode == IPC_WRITEFILE) {
            I->File = FileOpen(InOutPath,FileName,"wt");
         }
         else if (I->Mode == IPC_READFILE) {
            I->File = FileOpen(InOutPath,FileName,"rt");
         }
         else if (I->Mode == IPC_FFTB) {
            I->SocketRole = IPC_CLIENT; /* Spirent is Host */
            I->Socket = InitSocketClient(I->HostName,I->Port,I->AllowBlocking);
         }
      }
      fclose(infile);
}
/*********************************************************************/
/* Check if a socket peer has disconnected.                          */
/* Returns 1 if alive, 0 if dead.                                    */
/*********************************************************************/
static int SocketIsAlive(SOCKET sock)
{
   int error = 0;
   socklen_t len = sizeof(error);
   int retval = getsockopt(sock, SOL_SOCKET, SO_ERROR, &error, &len);
   if (retval != 0 || error != 0) return 0;

   /* Non-blocking peek to detect remote close */
   char buf;
   int n = recv(sock, &buf, 1, MSG_PEEK | MSG_DONTWAIT);
   if (n == 0) return 0; /* Peer closed connection */
   /* n < 0 with EAGAIN/EWOULDBLOCK means alive but no data yet */
   return 1;
}

/*********************************************************************/
void InterProcessComm(void)
{
      struct IpcType *I;
      long Iipc;

      pthread_mutex_lock(&IpcMutex);
      for(Iipc=0;Iipc<NipcSlots;Iipc++) {
         I = &IPC[Iipc];

         /* Skip slots with no active connection */
         if (!I->Init || I->Socket == 0) continue;

         /* Detect and clean up disconnected sockets */
         if (!SocketIsAlive(I->Socket)) {
            printf("IPC[%ld]: Socket %d disconnected, freeing slot.\n",
                   Iipc, (int)I->Socket);
            close(I->Socket);
            I->Socket = 0;
            I->Init = 0;
            I->Enabled = 0;
            continue;
         }

         if (I->Mode == IPC_TX) {
            if (I->SocketRole != IPC_GMSEC_CLIENT) {
               WriteToSocket(I->Socket,I->Prefix,I->Nprefix,I->EchoEnabled);
            }
            #ifdef _ENABLE_GMSEC_
            else {
               WriteToGmsec(ConnMgr,status,I->Prefix,I->Nprefix,I->EchoEnabled);
            }
            #endif
         }
         else if (I->Mode == IPC_RX) {
            if (I->SocketRole != IPC_GMSEC_CLIENT) {
               ReadFromSocket(I->Socket,I->EchoEnabled);
            }
            #ifdef _ENABLE_GMSEC_
            else {
               ReadFromGmsec(ConnMgr,status,I->EchoEnabled);
            }
            #endif
         }
         else if (I->Mode == IPC_TXRX) {
            if (I->SocketRole != IPC_GMSEC_CLIENT) {
               WriteToSocket(I->Socket,I->Prefix,I->Nprefix,I->EchoEnabled);
               ReadFromSocket(I->Socket,I->EchoEnabled);
            }
            #ifdef _ENABLE_GMSEC_
            else {
               WriteToGmsec(ConnMgr,status,I->Prefix,I->Nprefix,I->EchoEnabled);
               ReadFromGmsec(ConnMgr,status,I->EchoEnabled);
            }
            #endif
         }
         else if (I->Mode == IPC_WRITEFILE) {
            //WriteToFile(I->File,I->Prefix,I->Nprefix,I->EchoEnabled);
         }
         else if (I->Mode == IPC_READFILE) {
            //ReadFromFile(I->File,I->EchoEnabled);
         }
         #ifdef _ENABLE_FFTB_CODE_
         else if (I->Mode == IPC_FFTB) {
            SendStatesToSpirent();
         }
         #endif
      }
      pthread_mutex_unlock(&IpcMutex);
}

/* #ifdef __cplusplus
** }
** #endif
*/
