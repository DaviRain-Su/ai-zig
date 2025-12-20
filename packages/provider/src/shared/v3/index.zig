// Shared V3 Types
// Re-exports all shared types for the V3 provider specification

pub const shared_v3_headers = @import("shared-v3-headers.zig");
pub const shared_v3_provider_metadata = @import("shared-v3-provider-metadata.zig");
pub const shared_v3_provider_options = @import("shared-v3-provider-options.zig");
pub const shared_v3_warning = @import("shared-v3-warning.zig");

// Type exports
pub const SharedV3Headers = shared_v3_headers.SharedV3Headers;
pub const SharedV3ProviderMetadata = shared_v3_provider_metadata.SharedV3ProviderMetadata;
pub const SharedV3ProviderOptions = shared_v3_provider_options.SharedV3ProviderOptions;
pub const SharedV3Warning = shared_v3_warning.SharedV3Warning;

// Header utilities
pub const createHeaders = shared_v3_headers.createHeaders;
pub const headersFromSlice = shared_v3_headers.headersFromSlice;
pub const getHeader = shared_v3_headers.getHeader;
pub const setHeader = shared_v3_headers.setHeader;
pub const removeHeader = shared_v3_headers.removeHeader;
pub const mergeHeaders = shared_v3_headers.mergeHeaders;
pub const headersToSlice = shared_v3_headers.headersToSlice;
pub const hasHeader = shared_v3_headers.hasHeader;

// Provider metadata utilities
pub const createProviderMetadata = shared_v3_provider_metadata.createProviderMetadata;
pub const getProviderData = shared_v3_provider_metadata.getProviderData;
pub const setProviderData = shared_v3_provider_metadata.setProviderData;
pub const mergeProviderMetadata = shared_v3_provider_metadata.mergeProviderMetadata;

// Provider options utilities
pub const createProviderOptions = shared_v3_provider_options.createProviderOptions;
pub const getProviderOptions = shared_v3_provider_options.getProviderOptions;
pub const setProviderOptions = shared_v3_provider_options.setProviderOptions;
pub const getOption = shared_v3_provider_options.getOption;

test {
    // Run all tests from submodules
    @import("std").testing.refAllDecls(@This());
}
