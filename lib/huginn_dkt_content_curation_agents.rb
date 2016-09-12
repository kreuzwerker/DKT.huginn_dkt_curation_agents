require 'huginn_agent'

HuginnAgent.load 'huginn_dkt_content_curation_agents/concerns/dkt_nif_api_agent_concern'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_document_classification_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_ner_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_topic_modelling_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_clustering_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_smt_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_logging_agent'
HuginnAgent.register 'huginn_dkt_content_curation_agents/dkt_sesame_store_agent'
