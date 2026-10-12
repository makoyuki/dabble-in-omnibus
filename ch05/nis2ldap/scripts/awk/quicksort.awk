function quicksort(idxs, data, left, right,    i, j, last)
{
    if (left >= right){
        return;
    }
    pivot = int( left + (right - left) * rand() );
    quicksort_swap(idxs, left, pivot);
    last = left;
    for (i = left + 1; i <= right; i++){
	j = idxs[left];
        if ( data[idxs[i]] < data[j] ){
	    quicksort_swap(idxs, ++last, i);
	}
    }
    quicksort_swap(idxs, left, last);
    quicksort(idxs, data, left , last - 1);
    quicksort(idxs, data, last + 1, right);
}
function quicksort_swap(data, i, j,      temp)
{
    temp = data[i]
    data[i] = data[j]
    data[j] = temp
}
function quicksort_cmpint(idxs, data, left, right,    i, j, last)
{
    if (left >= right){
        return;
    }
    pivot = int( left + (right - left) * rand() );
    quicksort_swap(idxs, left, pivot);
    last = left;
    for (i = left + 1; i <= right; i++){
	j = idxs[left];
        if ( int(data[idxs[i]]) < int(data[j]) ){
	    quicksort_swap(idxs, ++last, i);
	}
    }
    quicksort_swap(idxs, left, last);
    quicksort_cmpint(idxs, data, left , last - 1);
    quicksort_cmpint(idxs, data, last + 1, right);
}
