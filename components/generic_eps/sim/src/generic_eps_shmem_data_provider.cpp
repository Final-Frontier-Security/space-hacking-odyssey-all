#include <generic_eps_shmem_data_provider.hpp>

namespace Nos3
{
    REGISTER_DATA_PROVIDER(Generic_epsShmemDataProvider,"GENERIC_EPS_SHMEM_PROVIDER");

    extern ItcLogger::Logger *sim_logger;

    Generic_epsShmemDataProvider::Generic_epsShmemDataProvider(const boost::property_tree::ptree& config) : SimIDataProvider(config)
    {
        sim_logger->trace("Generic_epsShmemDataProvider::Generic_epsShmemDataProvider:  Constructor executed");

        const std::string shm_name = config.get("simulator.hardware-model.data-provider.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't let this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());

        _orb = config.get("simulator.hardware-model.data-provider.orbit", 0);
        _sc  = config.get("simulator.hardware-model.data-provider.spacecraft", 0);
    }

    boost::shared_ptr<SimIDataPoint> Generic_epsShmemDataProvider::get_data_point(void) const
    {
        sim_logger->trace("Generic_epsShmemDataProvider::get_data_point:  Executed");

        /* Get the 42 data */
        boost::shared_ptr<Generic_epsDataPoint> dp;
        {
            dp = boost::shared_ptr<Generic_epsDataPoint>(
                new Generic_epsDataPoint(_orb, _sc, 
                    _blackboard_data->CSSValid[0] || _blackboard_data->CSSValid[1] || _blackboard_data->CSSValid[2] ||
                    _blackboard_data->CSSValid[3] || _blackboard_data->CSSValid[4] || _blackboard_data->CSSValid[5], 
                    _blackboard_data->svb));
        }
        return dp;
    }
}
