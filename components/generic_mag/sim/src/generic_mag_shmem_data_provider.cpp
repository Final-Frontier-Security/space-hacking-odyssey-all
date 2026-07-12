#include <generic_mag_shmem_data_provider.hpp>

namespace Nos3
{
    REGISTER_DATA_PROVIDER(Generic_magShmemDataProvider,"GENERIC_MAG_SHMEM_PROVIDER");

    extern ItcLogger::Logger *sim_logger;

    Generic_magShmemDataProvider::Generic_magShmemDataProvider(const boost::property_tree::ptree& config) : SimIDataProvider(config)
    {
        sim_logger->trace("Generic_magShmemDataProvider::Generic_magShmemDataProvider:  Constructor executed");
        const std::string shm_name = config.get("simulator.hardware-model.data-provider.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't let this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());    
    }

    boost::shared_ptr<SimIDataPoint> Generic_magShmemDataProvider::get_data_point(void) const
    {
        boost::shared_ptr<Generic_magDataPoint> dp;
        {
            dp = boost::shared_ptr<Generic_magDataPoint>(
                new Generic_magDataPoint(_blackboard_data->bvb[0], _blackboard_data->bvb[1], _blackboard_data->bvb[2]));
        }
        std::vector<float> values = dp->getValues();
        sim_logger->debug("Generic_magDataPoint::get_data_point: magnetic field=%f, %f, %f",
            values[0], values[1], values[2]);
        return dp;
    }
}
