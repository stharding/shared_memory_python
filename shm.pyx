from posix.mman cimport (
    mmap,
    shm_open,
    PROT_READ,
    PROT_WRITE,
    MAP_SHARED,
)
from posix.fcntl cimport (
    O_RDWR,
    O_CREAT
)
from posix.unistd cimport ftruncate

from libc.stdlib cimport malloc, free

cdef struct foo:
    int bar
    int baz

cdef class Foo:
    cdef foo* _foo
    cdef bint free_on_dealloc

    def __init__(self, bar=0, baz=0):
        self._foo = <foo*>malloc(sizeof(foo))
        self.bar = bar
        self.baz = baz
        self.free_on_dealloc = True

    def __dealloc__(self):
        if self.free_on_dealloc:
            free(self._foo)

    @staticmethod
    cdef Foo from_foo(foo* the_foo):
        cdef Foo c = Foo()
        free(c._foo)
        c._foo = the_foo
        return c

    @property
    def bar(self):
        return self._foo[0].bar

    @bar.setter
    def bar(self, int val):
        self._foo[0].bar = val

    @property
    def baz(self):
        return self._foo[0].baz

    @baz.setter
    def baz(self, int val):
        self._foo[0].baz = val


    @property
    def as_bytes(self):
        return str((<char*>self._foo)[:sizeof(foo)])

    @classmethod
    def from_bytes(cls, bytes foo_bytes):
        return Foo.from_foo(<foo*>(<char*>foo_bytes))

    def __len__(self):
        return sizeof(foo)

    def __repr__(self):
        return self.__class__.__name__ + '({self.bar}, {self.baz})'.format(self=self)

def foo_from_shm(bytes tagname):
    """
    Opens a shared memory segment by name (or creates a new one if there
    are no existing named segments matching the provided name).

    The Shared memory is presented as a Foo instance. Setting the fields
    on the Foo instance will update the shared memory for all
    participating processes.
    """

    cdef int fd
    fd = shm_open(<const char*>tagname, O_RDWR | O_CREAT, 0666)
    ftruncate(fd, sizeof(foo))
    ret_foo = Foo.from_foo(<foo*>(mmap(
        NULL, sizeof(foo), PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0)
    ))
    ret_foo.free_on_dealloc = False
    return ret_foo

def foo_from_mmap(file_name):
    """
    Opens a shared memory segment by memory mapping a file with the given
    path.

    This will raise an error if the file does not exist.

    The Shared memory is presented as a Foo instance. Setting the fields
    on the Foo instance will update the shared memory for all
    participating processes.

    A bus error will occur when the Foo instance is modified if the file
    is not long enough to contain a Foo instance (i.e. sizeof(foo))
    """

    with open(file_name, 'ra+b') as f:
        ret_foo = Foo.from_foo(<foo*>(mmap(
            NULL, sizeof(foo), PROT_READ|PROT_WRITE, MAP_SHARED, f.fileno(), 0)
        ))
        ret_foo.free_on_dealloc = False
        return ret_foo

