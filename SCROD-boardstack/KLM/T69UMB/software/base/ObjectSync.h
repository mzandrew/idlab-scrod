#ifndef INCLUDE_OBJECT_SYNC
#define INCLUDE_OBJECT_SYNC

#include <queue>
#include <pthread.h>

template<class T>
class ObjectSync
	/// Class holding a list of objects, that can be added from differrent
	/// treads and pooled from a single one.
{
public:
	ObjectSync();
		/// Constructor.
	
	virtual ~ObjectSync();
		/// Destructor.

	void insert(const T* object);
		/// Inserts an object to the list.

	T* getObject();
		/// Returns object if present, otherwise blocks.

protected:

private:
	
private:

	std::queue<T*>  _data;
	pthread_mutex_t _data_mutex;
	pthread_cond_t  _data_cv;

};

template<class T>
ObjectSync<T>::ObjectSync()
{
	pthread_mutex_init(&_data_mutex, NULL);
	pthread_cond_init (&_data_cv, NULL);
}

template<class T>
ObjectSync<T>::~ObjectSync()
{
	pthread_mutex_destroy(&_data_mutex);
	pthread_cond_destroy(&_data_cv);
}

template<class T>
void ObjectSync<T>::insert(const T* object)
{
	pthread_mutex_lock(&_data_mutex);
	_data.push(object);
	// notify that it's not empty anymore
	pthread_cond_signal(&_data_cv);
	pthread_mutex_unlock(&_data_mutex);
}

template<class T>
T* ObjectSync<T>::getObject()
{
	T* tmp;

	// remove it from the list
	pthread_mutex_lock(&_data_mutex);
	// wait for the object to be available
	pthread_cond_wait(&_data_cv, &_data_mutex);
	tmp = _data.front();
	_data.pop();	
	pthread_mutex_unlock(&_data_mutex);
	return tmp;
}


#endif
