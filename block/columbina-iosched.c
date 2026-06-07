/*
 * elevator columbina (noop-based)
 */
#include <linux/blkdev.h>
#include <linux/elevator.h>
#include <linux/bio.h>
#include <linux/module.h>
#include <linux/slab.h>
#include <linux/init.h>

struct moon_data {
	struct list_head queue;
};

static void moon_merged_requests(struct request_queue *q, struct request *rq,
				 struct request *next)
{
	list_del_init(&next->queuelist);
}

static int moon_dispatch(struct request_queue *q, int force)
{
    struct moon_data *nd = q->elevator->elevator_data;
    struct request *rq, *tmp;
    int dispatched = 0;
    const int max_read_batch = 4;
    static int read_latency_counter = 0; 

    if (list_empty(&nd->queue))
        return 0;

   //passed 16 writes in consecutive reads
if (read_latency_counter >= 16) {
        read_latency_counter = 0;
        list_for_each_entry_safe(rq, tmp, &nd->queue, queuelist) {
            if (rq_data_dir(rq) == WRITE) {
                list_del_init(&rq->queuelist);
                elv_dispatch_sort(q, rq);
                return 1;
            }
        }
    }

    list_for_each_entry_safe(rq, tmp, &nd->queue, queuelist) {
        if (rq_data_dir(rq) == READ) {
            list_del_init(&rq->queuelist);
            elv_dispatch_sort(q, rq);
            dispatched++;
			read_latency_counter++;
            
            if (dispatched >= max_read_batch)
                break; 
        }
    }

    if (dispatched == 0 && !list_empty(&nd->queue)) {
        rq = list_first_entry(&nd->queue, struct request, queuelist);
        list_del_init(&rq->queuelist);
        elv_dispatch_sort(q, rq);
        dispatched++;
		read_latency_counter = 0;
    }

    return dispatched > 0;
}

static void moon_add_request(struct request_queue *q, struct request *rq)
{
	struct moon_data *nd = q->elevator->elevator_data;

	list_add_tail(&rq->queuelist, &nd->queue);
}

static struct request *
moon_former_request(struct request_queue *q, struct request *rq)
{
	struct moon_data *nd = q->elevator->elevator_data;

	if (rq->queuelist.prev == &nd->queue)
		return NULL;
	return list_prev_entry(rq, queuelist);
}

static struct request *
moon_latter_request(struct request_queue *q, struct request *rq)
{
	struct moon_data *nd = q->elevator->elevator_data;

	if (rq->queuelist.next == &nd->queue)
		return NULL;
	return list_next_entry(rq, queuelist);
}

static int moon_init_queue(struct request_queue *q, struct elevator_type *e)
{
	struct moon_data *nd;
	struct elevator_queue *eq;

	eq = elevator_alloc(q, e);
	if (!eq)
		return -ENOMEM;

	nd = kmalloc_node(sizeof(*nd), GFP_KERNEL, q->node);
	if (!nd) {
		kobject_put(&eq->kobj);
		return -ENOMEM;
	}
	eq->elevator_data = nd;

	INIT_LIST_HEAD(&nd->queue);

	spin_lock_irq(q->queue_lock);
	q->elevator = eq;
	spin_unlock_irq(q->queue_lock);
	return 0;
}

static void moon_exit_queue(struct elevator_queue *e)
{
	struct moon_data *nd = e->elevator_data;

	BUG_ON(!list_empty(&nd->queue));
	kfree(nd);
}

static struct elevator_type elevator_moon = {
	.ops.sq = {
		.elevator_merge_req_fn		= moon_merged_requests,
		.elevator_dispatch_fn		= moon_dispatch,
		.elevator_add_req_fn		= moon_add_request,
		.elevator_former_req_fn		= moon_former_request,
		.elevator_latter_req_fn		= moon_latter_request,
		.elevator_init_fn		= moon_init_queue,
		.elevator_exit_fn		= moon_exit_queue,
	},
	.elevator_name = "columbina",
	.elevator_owner = THIS_MODULE,
};

static int __init moon_init(void)
{
	return elv_register(&elevator_moon);
}

static void __exit moon_exit(void)
{
	elv_unregister(&elevator_moon);
}

module_init(moon_init);
module_exit(moon_exit);


MODULE_AUTHOR("Jens Axboe");
MODULE_AUTHOR("Anomaly-arc");
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("columbina, No-op based");