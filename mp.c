#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>
#include <pthread.h>

// infrastructure, unneccesarily flexible
// can ignore, not important

struct node {
   void *data;
   struct node* next;
};

struct list {
   struct node *head;
   struct node *tail;
   int (*comparator)(void *, void *);
};


struct actor_register {
   int id;
   int (*send)(void *);
};

int compare(void *d1, void *d2) {
   struct actor_register *a1, *a2;
   a1 = (struct actor_register *) d1;
   a2 = (struct actor_register *) d2;
   return a1->id - a2->id;
}

struct list* list_new(int (*comparator)(void *, void *)) {
   struct list* new = malloc(sizeof(struct list));
   new->comparator = comparator;
   new->head = NULL;
   new->tail = NULL; 
   return new;
}

struct list* list_add(struct list *l, void *data) {
   struct node* new = malloc(sizeof(struct node));
   new->next = NULL;
   new->data = data;
   if (l->head == NULL) {
      l->head = new;
      l->tail = new;
   } else {
      l->tail->next = new;
      l->tail = new;
   }
   return l;
}


void *list_search(struct list* l, void *data) {
   struct node* tmp;
   for (tmp = l->head; tmp != NULL; tmp = tmp->next) {
      if (l->comparator(tmp->data, data) == 0) {
         return tmp->data;
      } 
   } 
   return NULL;
}

// real beginning of the program


// basic idea is that we register an "address book", which has a list of
// "send message" functions. 

// we initialise the address list before the start of the program,
// and then call two threads, each with their own program flow.
// theoretically you wouldn't be limited to one message passing program per
// thread, but without an object model, it would be too much clutter to write
// all the functions to prove this concept.

// from each thread, the calling "object" registers itself with the address
// list, then enters its normal state of execution. 
// they randomly send messages to the other thread, and on successful send,
// they sleep for 2 seconds, to make the send/receive cycle noticable.

// the address book is a list of 'struct actor_register', where each actor
// has a struct which holds their id, and their specific callback.

// the address book is just a standard list with some genericity added in

struct list *address_book;

void add_address(int id, int (*send)(void *)) {
   struct actor_register *x = malloc(sizeof(*x));
   x->id = id;
   x->send = send;
   assert(address_book != NULL);
   address_book = list_add(address_book, x);
}

void send_message(int sender, int receiver, void *data) {
   struct actor_register a;
   a.id = receiver;
   void *tmp_address = list_search(address_book, (void *) &a);
   if (tmp_address != NULL) {
      struct actor_register *address = (struct actor_register *) tmp_address;
      address->send(data);
      printf("%d: send data to %d.\n", sender, receiver);
   }
}

// messages are stored in global space because of no object model and
// because it's easy.

int message1;
int message2;

// just imagine these to be in their own namespace.

int first_message(void *data) {
   int *dref = (int *) data;
   message1 = *dref;
   printf("1: received message from 2: %d\n", message1);
   return message1;
}

int second_message(void *data) {
   int *dref = (int *) data;
   message2 = *dref;
   printf("2: received message from 1: %d\n", message2);
   return message2;
}

void *first_thread(void *args) {
   int *data = malloc(sizeof(*data));
   add_address(1, first_message);
   while(1) {
      int rnd = rand() % 10000;
      if (rnd < 2000) {
         *data = rnd;
         send_message(1, 2, (void *) data);
         sleep(2);
      }
   }
   return NULL;
}

void *second_thread(void *args) {
   int *data = malloc(sizeof(*data));
   add_address(2, second_message);
   while(1) {
      int rnd = rand() % 10000;
      if (rnd < 3000) {
         *data = rnd;
         sleep(2);
         send_message(2, 1, (void *) data);
         sleep(2);
      }
   }
   return NULL;
}

// boilerplate

int main(int argc, char **argv) {
   address_book = list_new(compare);
   pthread_t thread1, thread2;
   srand(0);
   pthread_create(&thread1, NULL, &first_thread, NULL);
   pthread_create(&thread2, NULL, &second_thread, NULL);
   pthread_join(thread1, NULL);
   pthread_join(thread2, NULL);
   return 0;
}
