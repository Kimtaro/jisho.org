#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define MAX_LINE 1024

// ==============
// = List stuff =
// ==============

typedef struct list_node {
	char bigram[MAX_LINE];
	unsigned int count;
	
	struct list_node *next;
	struct list_node *previous;
} list_node_t;

typedef struct list {
	unsigned int count;
	
	list_node_t *first;
	list_node_t *last;
} list_t;


list_t *create_list(void);
list_node_t *create_node_with_data(char *bigram, unsigned int count);
void list_append_node(list_t *list, list_node_t *node);
void list_insert_node_before_node(list_t *list, list_node_t *node, list_node_t *before_node);
void list_insert_node_sorted(list_t *list, list_node_t *node);
list_node_t *list_find_node_for_bigram(list_t *list, char *bigram);
void list_remove_node(list_t *list, list_node_t *node);


list_t *create_list(void) {
	list_t *list = malloc(sizeof(list_t));
	
	return list;
}

list_node_t *create_node_with_data(char *bigram, unsigned int count) {
	list_node_t *node = malloc(sizeof(list_node_t));
	
	strlcpy(node->bigram, bigram, MAX_LINE);
	node->count = count;
	
	return node;
}

void list_append_node(list_t *list, list_node_t *node) {
	if ( !list->first ) {
		list->first = node;
	}
	
	if ( list->last ) {
		list->last->next = node;
	}
	
	node->previous = list->last;
	node->next = NULL;
	
	list->last = node;
	list->count++;
}

void list_insert_node_before_node(list_t *list, list_node_t *node, list_node_t *before_node) {
	if ( list->first == before_node ) {
		list->first = node;
	}
	
	node->previous = before_node->previous;
	node->next = before_node;
	
	if ( before_node->previous ) {
		before_node->previous->next = node;
	}
	
	before_node->previous = node;
	
	list->count++;
}

void list_insert_node_sorted(list_t *list, list_node_t *node) {
	list_node_t *each_node;
	
	if ( list->count == 0 ) {
		list_append_node(list, node);
	}
	else {
		for ( each_node = list->first; each_node; each_node = each_node->next) {
			if ( each_node->count >= node->count ) {
				list_insert_node_before_node(list, node, each_node);
				
				return;
			}
		}
		
		list_append_node(list, node);
	}
}

list_node_t *list_find_node_for_bigram(list_t *list, char *bigram){
	list_node_t *each_node;
	
	for ( each_node = list->first; each_node; each_node = each_node->next ) {
		if ( strcmp(each_node->bigram, bigram) == 0 ) {
			return each_node;
		}
	}
	
	return NULL;
}

void list_remove_node(list_t *list, list_node_t *node) {
	if ( node->previous )
		node->previous->next = node->next;
	
	if ( node->next )
		node->next->previous = node->previous;
	
	if ( node == list->first )
		list->first = node->next;
	
	if ( node == list->last )
		list->last = node->previous;
	
	free(node);
	list->count--;
}


// ========
// = Main =
// ========

int main (int argc, char **argv) {
	char *program_name = argv[0];
	char *data_filename = argv[1];
	char *wanted_word = argv[2];	
	FILE *data_file;
	char line[MAX_LINE];
	char left_word[MAX_LINE];
	char right_word[MAX_LINE];
	list_t *list = create_list();
	char current_bigram[MAX_LINE];
	list_node_t *current_node;
	list_node_t *new_node;
	
	
	// =============
	// = Open file =
	// =============
	if ( (data_file = fopen(data_filename, "r")) == NULL ) {
		fprintf(stderr, "%s: can't open %s\n", program_name, data_filename);
		exit(1);
	}
	
	
	// ========
	// = Read =
	// ========
	//int i = 0;
	while ( fgets(line, MAX_LINE, data_file) != NULL ) {
		if ( sscanf(line, "%s %s", left_word, right_word) == 2 ) {			
			if ( strcmp(left_word, wanted_word) == 0) {
				snprintf(current_bigram, sizeof(current_bigram), "%s %s", left_word, right_word);
				
				if ( (current_node = list_find_node_for_bigram(list, current_bigram)) != NULL ) {
					new_node = create_node_with_data(current_bigram, ++current_node->count);
										
					list_remove_node(list, current_node);
					
					list_insert_node_sorted(list, new_node);
				}
				else {
					new_node = create_node_with_data(current_bigram, 1);
					list_insert_node_sorted(list, new_node);
				}
				
				//printf("# %s # %s, %d\n", current_bigram, new_node->bigram, new_node->count);
			}
			else {
				continue;
			}
			// if (i++ == 1000)
			// 				exit(0);
		}
		
		// current_node = list->first;
		// 				while ( current_node != NULL ) {
		// 					printf("%s: %d (previous: %p, node: %p, next: %p)\n", current_node->bigram, current_node->count, current_node->previous, current_node, current_node->next);
		// 					current_node = current_node->next;
		// 				}
		// 				printf("-----------------\n");
		// 				
		// 				if (i++ == 100)
		// 					exit(0);
	}
	
	
	// =========
	// = Print =
	// =========
	current_node = list->first;
	while ( current_node != NULL ) {
		printf("%s: %d\n", current_node->bigram, current_node->count);
		current_node = current_node->next;
	}
	
	
	return 0;
}