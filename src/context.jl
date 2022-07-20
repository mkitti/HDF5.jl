struct HDF5Context
   attribute_access::HDF5.AttributeAccessProperties
   attribute_create::HDF5.AttributeCreateProperties
   dataset_access  ::HDF5.DatasetAccessProperties
   dataset_create  ::HDF5.DatasetCreateProperties
   dataset_transfer::HDF5.DatasetTransferProperties
   datatype_access ::HDF5.DatatypeAccessProperties
   datatype_create ::HDF5.DatatypeCreateProperties
   file_access     ::HDF5.FileAccessProperties
   file_create     ::HDF5.FileCreateProperties
   file_mount      ::HDF5.FileMountProperties
   group_access    ::HDF5.GroupAccessProperties
   group_create    ::HDF5.GroupCreateProperties
   link_access     ::HDF5.LinkAccessProperties
   link_create     ::HDF5.LinkCreateProperties
   object_copy     ::HDF5.ObjectCopyProperties
   object_create   ::HDF5.ObjectCreateProperties
   string_create   ::HDF5.StringCreateProperties
end

function HDF5Context()
   HDF5Context(
       HDF5.AttributeAccessProperties(),
       HDF5.AttributeCreateProperties(),
       HDF5.DatasetAccessProperties(),
       HDF5.DatasetCreateProperties(),
       HDF5.DatasetTransferProperties(),
       HDF5.DatatypeAccessProperties(),
       HDF5.DatatypeCreateProperties(),
       HDF5.FileAccessProperties(),
       HDF5.FileCreateProperties(),
       HDF5.FileMountProperties(),
       HDF5.GroupAccessProperties(),
       HDF5.GroupCreateProperties(),
       HDF5.LinkAccessProperties(),
       HDF5.LinkCreateProperties(),
       HDF5.ObjectCopyProperties(),
       HDF5.ObjectCreateProperties(),
       HDF5.StringCreateProperties(),
   )
end

function Base.copy(x::HDF5Context)
    fields = map(fieldnames(HDF5Context)) do fieldname
        copy(getfield(x, fieldname))
    end
    return HDF5Context(fields...)
end

function Base.close(x::HDF5Context)
    foreach(fieldnames(HDF5Context)) do fieldname
        close(getfield(context, fieldname))
    end
    return nothing
end

const CONTEXT = HDF5Context()

function create_local_context(context)
    tls = task_local_storage()
    if !haskey(tls, :hdf5context)
        tls[:hdf5_context] = context
    end
end
function create_local_context()
    tls = task_local_storage()
    if !haskey(tls, :hdf5context)
        tls[:hdf5_context] = copy(CONTEXT)
    end
end

function delete_local_context!()
    tls = task_local_storage()
    if haskey(tls, :hdf5_context)
        context = pop!(tls, :hdf5_context)
        close(context)
    end
    return nothing
end

function local_context(f::Function, context = copy(CONTEXT))
    fetch(
        @async begin
            local_context = create_local_context(context)
            try
                f(local_context)
            finally
                delete_local_context!()
            end
        end
    )
end

function get_context()
    return get(task_local_storage(), :hdf5_context, CONTEXT)
end

function get_context_property(name::Symbol)
    local_context = get_context()
    return getfield(local_context, name)
end

"""
    get_access_context(::Type{T})

Get the access context property list for `T`.
"""
get_access_context(::Type{Attribute}) = get_context_property(:attribute_access)
get_access_context(::Type{Dataset}) = get_context_property(:dataset_access)
get_access_context(::Type{DataType}) = get_context_property(:datatype_access)
get_access_context(::Type{File}) = get_context_property(:file_access)
get_access_context(::Type{Group}) = get_context_property(:group_access)
#get_access_context(::Type{Link}) = get_context_property(:link_access)

"""
    get_create_context(::Type{T})

Get the create context property list for `T`.
"""
get_create_context(::Type{Attribute}) = get_context_property(:attribute_create)
get_create_context(::Type{Dataset}) = get_context_property(:dataset_create)
get_create_context(::Type{DataType}) = get_context_property(:datatype_create)
get_create_context(::Type{File}) = get_context_property(:file_create)
get_create_context(::Type{Group}) = get_context_property(:group_create)
#get_create_context(::Type{Link}) = get_context_property(:link_create)

"""
    get_access_context(obj)

Return the access context property list for `typeof(obj)` if its valid.
Otherwise, return the access property list of obj.
"""
function get_access_context(obj::T) where T
    cp = get_access_context(T)
    isvalid(cp) ? cp : get_access_properties(obj)
end

"""
    get_create_context(obj)

Return the create context property list for `typeof(obj)` if it is valid.
Otherwise, return the create property list of obj.
"""
function get_create_context(obj::T) where T
    cp = get_create_context(T)
    isvalid(cp) ? cp : get_create_properties(obj)
end