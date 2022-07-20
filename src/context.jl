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
    # TODO: create context copy using `H5Pcopy` ?
    HDF5Context()
end

const CONTEXT = HDF5Context()

function get_context_property(name::Symbol)
    local_context = get(task_local_storage(), :hdf5_context, CONTEXT)
    property = getfield(local_context, name)
    isvalid(property) ? property : nothing
end